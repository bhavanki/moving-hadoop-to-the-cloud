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
public class WikipediaDumpETLDriver extends Configured implements Tool {

  @Override
  public int run(String[] args) throws Exception {
    // arg checks

    JobConf conf = new JobConf(getClass());
    conf.setJobName("WP dump ETL");

    conf.setMapperClass(WikipediaDumpETLMapper.class);
    conf.setNumReduceTasks(0);
    conf.setOutputKeyClass(Text.class);
    conf.setOutputValueClass(Text.class);

    conf.setInputFormat(StreamInputFormat.class);
    StreamInputFormat.addInputPath(conf, new Path(args[0]));
    conf.set("stream.recordreader.class",
             "org.apache.hadoop.streaming.StreamXmlRecordReader");
    conf.set("stream.recordreader.begin", "<page>");
    conf.set("stream.recordreader.end", "</page>");
    conf.setOutputFormat(SequenceFileOutputFormat.class);
    SequenceFileOutputFormat.setOutputPath(conf, new Path(args[1]));

    JobClient.runJob(conf);
    return 0;
  }

  public static void main(String[] args) throws Exception {
    int exitCode = ToolRunner.run(new WikipediaDumpETLDriver(), args);
    System.exit(exitCode);
  }
}
