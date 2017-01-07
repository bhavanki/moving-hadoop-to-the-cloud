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
import com.amazonaws.services.kinesis.model.PutRecordRequest;
import com.amazonaws.services.kinesis.model.PutRecordResult;
import com.github.javafaker.Faker;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.time.format.DateTimeFormatter;
import java.time.ZonedDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Random;
import org.apache.commons.math3.distribution.EnumeratedDistribution;
import org.apache.commons.math3.util.Pair;

/**
 * A generator for fake Apache access log lines which submits each line to an
 * Amazon Kinesis stream.
 */
public class LogGenerator {

  private static final String PARTITION_KEY = "thekey";

  /**
   * Generates log lines and sends them to Kinesis.
   *
   * @param streamName Kinesis stream name
   * @param recsPerSecond number of records to send each second
   * @param numRecords total number of records to send
   */
  public void generate(String streamName, int recsPerSecond, int numRecords)
    throws InterruptedException {

    AmazonKinesisClient client = new AmazonKinesisClient();

    int numPasses = (numRecords + recsPerSecond - 1) / recsPerSecond;
    int recordsLeft = numRecords;
    for (int i = 0; i < numPasses; i++) {
      int numToGenerate = Math.min(recordsLeft, recsPerSecond);
      for (int j = 0; j < numToGenerate; j++) {
        String logLine = generateLogLine();

        PutRecordRequest request = new PutRecordRequest()
          .withStreamName(streamName)
          .withPartitionKey(PARTITION_KEY)
          .withData(ByteBuffer.wrap(logLine.getBytes(StandardCharsets.UTF_8)));
        PutRecordResult result = client.putRecord(request);
        System.out.println(String.format("Wrote to shard %s as %s", result.getShardId(),
                                         result.getSequenceNumber()));
      }

      recordsLeft -= numToGenerate;
      if (recordsLeft > 0) {
        Thread.sleep(1000L);
      }
    }
  }

  private static final String FORMAT =
    "%s - - [%s] \"%s %s HTTP/1.0\" %s %d \"%s\" \"%s\"";

  private Random random = new Random();
  private Faker faker = new Faker();
  private static final DateTimeFormatter TIMESTAMP_FORMATTER =
    DateTimeFormatter.ofPattern("dd/MMM/yyyy:HH:mm:ss Z");
  private static final EnumeratedDistribution<String> METHODS = makeDistribution(
    Pair.create("GET", 6.0),
    Pair.create("POST", 2.0),
    Pair.create("PUT", 1.0)
  );
  private static final EnumeratedDistribution<String> RESOURCES = makeDistribution(
    Pair.create("/page1", 10.0),
    Pair.create("/page2", 9.0),
    Pair.create("/page3", 7.0),
    Pair.create("/page4", 3.0),
    Pair.create("/secretpage", 0.5)
  );
  private static final EnumeratedDistribution<String> RESPONSES = makeDistribution(
    Pair.create("200", 8.0),
    Pair.create("404", 2.0),
    Pair.create("401", 0.5),
    Pair.create("403", 0.5)
  );
  // see NOTICE.md for license information for user agent strings below
  private static final EnumeratedDistribution<String> USER_AGENTS = makeDistribution(
    Pair.create("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36", 4.7),
    Pair.create("Mozilla/5.0 (Windows NT 10.0; WOW64; rv:50.0) Gecko/20100101 Firefox/50.0", 3.8),
    Pair.create("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_1) AppleWebKit/602.2.14 (KHTML, like Gecko) Version/10.0.1 Safari/602.2.14", 2.5),
    Pair.create("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.95 Safari/537.36", 2.2),
    Pair.create("Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:50.0) Gecko/20100101 Firefox/50.0", 2.1)
  );

  private static EnumeratedDistribution<String> makeDistribution(Pair<String, Double>... items) {
    return new EnumeratedDistribution<String>(Arrays.asList(items));
  }

  private String generateLogLine() {
    String ipAddress = faker.internet().privateIpV4Address();
    String datetime = TIMESTAMP_FORMATTER.format(ZonedDateTime.now());
    String method = METHODS.sample();
    String resource = RESOURCES.sample();
    String status = RESPONSES.sample();
    int bytes = random.nextInt(10000);
    String referer = faker.internet().url();
    String userAgent = USER_AGENTS.sample();

    return String.format(FORMAT, ipAddress, datetime, method, resource, status, bytes, referer,
                         userAgent);
  }

  public static void main(String[] args) throws Exception {
    if (args.length != 3) {
      throw new IllegalArgumentException("Expected arguments: Kinesis stream name, " +
                                         "records per second, number of records");
    }

    new LogGenerator().generate(args[0], Integer.parseInt(args[1]),
                                Integer.parseInt(args[2]));
  }
}
