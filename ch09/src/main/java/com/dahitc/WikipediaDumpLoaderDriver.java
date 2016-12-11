/*
Copyright 2016 William A. Havanki, Jr.

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

package com.dahitc;

import org.apache.hadoop.conf.Configured;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapred.JobClient;
import org.apache.hadoop.mapred.JobConf;
import org.apache.hadoop.mapred.SequenceFileOutputFormat;
import org.apache.hadoop.streaming.StreamInputFormat;
import org.apache.hadoop.util.Tool;
import org.apache.hadoop.util.ToolRunner;

/**
 * Reads a Wikipedia XML dump file and extracts each article's text into
 * sequence files.
 */
public class WikipediaDumpLoaderDriver extends Configured implements Tool {

  @Override
  public int run(String[] args) throws Exception {
    // arg checks

    JobConf conf = new JobConf(getClass());
    conf.setJobName("WP dump loader");

    // Set the mapper class, but skip the reduce phase
    conf.setMapperClass(WikipediaDumpLoaderMapper.class);
    conf.setNumReduceTasks(0);
    // The object key/value pairs are text
    conf.setOutputKeyClass(Text.class);
    conf.setOutputValueClass(Text.class);

    // Stream XML into the job
    conf.setInputFormat(StreamInputFormat.class);
    StreamInputFormat.addInputPath(conf, new Path(args[0]));
    // Use the XML record reader, with each page as one record
    conf.set("stream.recordreader.class",
             "org.apache.hadoop.streaming.StreamXmlRecordReader");
    conf.set("stream.recordreader.begin", "<page>");
    conf.set("stream.recordreader.end", "</page>");
    // Emit sequence files
    conf.setOutputFormat(SequenceFileOutputFormat.class);
    SequenceFileOutputFormat.setOutputPath(conf, new Path(args[1]));

    JobClient.runJob(conf);
    return 0;
  }

  public static void main(String[] args) throws Exception {
    int exitCode = ToolRunner.run(new WikipediaDumpLoaderDriver(), args);
    System.exit(exitCode);
  }
}
