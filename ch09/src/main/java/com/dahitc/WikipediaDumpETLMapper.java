package com.dahitc;

import java.io.IOException;
import java.io.StringReader;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapred.JobConf;
import org.apache.hadoop.mapred.Mapper;
import org.apache.hadoop.mapred.MapReduceBase;
import org.apache.hadoop.mapred.OutputCollector;
import org.apache.hadoop.mapred.Reporter;
import org.w3c.dom.Document;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

/**
 * Mapper that parses the XML for a Wikipedia article and emits the article's
 * title and text content.
 */
public class WikipediaDumpETLMapper extends MapReduceBase
  implements Mapper<Text, Text, Text, Text> {

  private enum Counter { ARTICLES }

  private DocumentBuilder db;

  @Override
  public void configure(JobConf conf) {
    try {
      db = DocumentBuilderFactory.newInstance().newDocumentBuilder();
    } catch (ParserConfigurationException e) {
      throw new IllegalStateException("XML parser configuration is bad", e);
    }
  }

  /**
   * key = article content
   * value = empty string
   */
  @Override
  public void map(Text key, Text value, OutputCollector<Text, Text> output,
                  Reporter reporter) throws IOException {
    try {
      // Parse the page of XML into a document
      Document doc = db.parse(new InputSource(new StringReader(key.toString())));

      // Extract the title and text (article content) from the page content
      String title = doc.getElementsByTagName("title").item(0).getTextContent();
      String text = doc.getElementsByTagName("text").item(0).getTextContent();

      // Emit the title and text pair
      output.collect(new Text(title), new Text(text));
      reporter.getCounter(Counter.ARTICLES).increment(1L);
    } catch (SAXException e) {
      throw new IOException(e);
    }
  }
}
