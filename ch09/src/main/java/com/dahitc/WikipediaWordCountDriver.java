package com.dahitc;

import org.apache.hadoop.conf.Configured;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapred.JobClient;
import org.apache.hadoop.mapred.JobConf;
import org.apache.hadoop.mapred.SequenceFileInputFormat;
import org.apache.hadoop.mapred.TextOutputFormat;
import org.apache.hadoop.util.Tool;
import org.apache.hadoop.util.ToolRunner;

/**
 * Reads sequence files of Wikipedia text and counts words in them.
 */
public class WikipediaWordCountDriver extends Configured implements Tool {

  @Override
  public int run(String[] args) throws Exception {
    // arg checks

    JobConf conf = new JobConf(getClass());
    conf.setJobName("WP word count");

    conf.setMapperClass(WikipediaWordCountMapper.class);
    conf.setReducerClass(WikipediaWordCountReducer.class);
    conf.setReducerClass(WikipediaWordCountReducer.class);
    conf.setOutputKeyClass(Text.class);
    conf.setOutputValueClass(IntWritable.class);

    conf.setInputFormat(SequenceFileInputFormat.class);
    SequenceFileInputFormat.addInputPath(conf, new Path(args[0]));
    conf.setOutputFormat(TextOutputFormat.class);
    TextOutputFormat.setOutputPath(conf, new Path(args[1]));

    JobClient.runJob(conf);
    return 0;
  }

  public static void main(String[] args) throws Exception {
    int exitCode = ToolRunner.run(new WikipediaWordCountDriver(), args);
    System.exit(exitCode);
  }
}
