/*
Copyright 2017 William A. Havanki, Jr.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package com.mh2c;

import com.amazonaws.services.kinesis.AmazonKinesisClient;
import com.amazonaws.services.kinesis.clientlibrary.lib.worker.InitialPositionInStream;
import com.amazonaws.util.Md5Utils;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapred.TextOutputFormat;
import org.apache.spark.SparkConf;
import org.apache.spark.storage.StorageLevel;
import org.apache.spark.streaming.Duration;
import org.apache.spark.streaming.api.java.JavaDStream;
import org.apache.spark.streaming.api.java.JavaPairDStream;
import org.apache.spark.streaming.api.java.JavaStreamingContext;
import org.apache.spark.streaming.kinesis.KinesisUtils;
import scala.Tuple2;

/**
 * A Spark Streaming job that reads Apache log lines from a Kinesis stream,
 * processes them, and writes the results to Hadoop.
 */
public class LogProcessor {

  private static final String APP_NAME = "ApacheAccessLogProcessor";

  /**
   * Processes a Kinesis stream.
   *
   * @param streamName Kinesis stream name
   * @param region AWS region housing Kinesis stream
   * @param batchInterval streaming batch interval, in milliseconds
   * @param hadoopDir directory prefix in Hadoop where files are written
   * @throws InterruptedException if processing is interrupted
   */
  public void process(String streamName, String region, int batchInterval, String hadoopDir)
    throws InterruptedException {

    String kinesisEndpoint = String.format("https://kinesis.%s.amazonaws.com/", region);

    AmazonKinesisClient client = new AmazonKinesisClient();
    client.setEndpoint(kinesisEndpoint);

    int numShards = client.describeStream(streamName).getStreamDescription().getShards().size();
    SparkConf conf = new SparkConf().setAppName(APP_NAME);
    JavaStreamingContext ctx = new JavaStreamingContext(conf, new Duration(batchInterval));

    JavaDStream<byte[]> kinesisStream =
      KinesisUtils.createStream(ctx, APP_NAME, streamName, kinesisEndpoint, region,
                                InitialPositionInStream.LATEST, new Duration(batchInterval),
                                StorageLevel.MEMORY_AND_DISK_2());

    // Make more DStreams
    JavaDStream<ApacheLogRecord> processedRecords = kinesisStream
      .map(line -> new ApacheLogRecord(new String(line, StandardCharsets.UTF_8)))
      .map(record -> record.withIpAddress(anonymizeIpAddress(record.getIpAddress())))
      .map(record -> record.withUserAgent(categorizeUserAgent(record.getUserAgent())))
    ;

    // Only pair streams can be written as Hadoop files
    JavaPairDStream<String, ApacheLogRecord> markedRecords = processedRecords
      .transformToPair(recordRdd -> recordRdd.mapToPair(
                                      record -> new Tuple2<>(UUID.randomUUID().toString(), record)
                                    ));

    // Write out to Hadoop
    markedRecords.print();
    markedRecords.saveAsHadoopFiles(hadoopDir, "txt", Text.class, Text.class, TextOutputFormat.class);

    ctx.start();
    try {
      ctx.awaitTermination();
    } catch (InterruptedException e) {
      System.out.println("Streaming stopped");
      return;
    }
  }

  private static String anonymizeIpAddress(String ipAddress) {
    // Note that MD5 is not strong enough for production use
    return Md5Utils.md5AsBase64(ipAddress.getBytes(StandardCharsets.UTF_8));
  }

  private static String categorizeUserAgent(String userAgent) {
    if (userAgent.contains("OPR")) {
      return "OPERA";
    }
    if (userAgent.contains("Chrome")) {
      return "CHROME";
    }
    if (userAgent.contains("Safari")) {
      return "SAFARI";
    }
    if (userAgent.contains("Firefox")) {
      return "FIREFOX";
    }
    if (userAgent.contains("Trident")) {
      return "IE";
    }
    return "OTHER";
  }

  public static void main(String[] args) throws Exception {
    if (args.length != 4) {
      throw new IllegalArgumentException("Expected arguments: Kinesis stream name, " +
                                         "AWS region, batch interval in ms, HDFS output directory");
    }

    new LogProcessor().process(args[0], args[1], Integer.parseInt(args[2]), args[3]);
  }
}
