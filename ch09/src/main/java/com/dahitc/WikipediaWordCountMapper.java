package com.dahitc;

import java.io.IOException;

import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapred.Mapper;
import org.apache.hadoop.mapred.MapReduceBase;
import org.apache.hadoop.mapred.OutputCollector;
import org.apache.hadoop.mapred.Reporter;

/**
 * Mapper that takes in Wikipedia article text and counts the words in it.
 */
public class WikipediaWordCountMapper extends MapReduceBase
  implements Mapper<Text, Text, Text, IntWritable> {

  private static final IntWritable ONE = new IntWritable(1);
  private Text wordText = new Text();

  /**
   * key = title
   * value = text
   */
  @Override
  public void map(Text key, Text value, OutputCollector<Text, IntWritable> output,
                  Reporter reporter) throws IOException {
    // Split the text content of the article on whitespace
    String[] words = value.toString().split("\\s+");
    // Count each word occurrence
    for (String word : words) {
      wordText.set(word);
      output.collect(wordText, ONE);
    }
  }
}
