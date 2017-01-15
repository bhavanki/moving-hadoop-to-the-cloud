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

import java.io.Serializable;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * A class representing a simplified Apache access log record.
 */
public class ApacheLogRecord implements Serializable {

  private final String ipAddress;
  private final ZonedDateTime dateTime;
  private final String method;
  private final String resource;
  private final int status;
  private final long bytes;
  private final String userAgent;

  /**
   * Creates a new record.
   *
   * @param ipAddress IP address
   * @param dateTime timestamp
   * @param method HTTP method
   * @param resource URL of resource accessed
   * @param status HTTP response code
   * @param bytes number of bytes in response
   * @param userAgent user agent string
   */
  public ApacheLogRecord(String ipAddress, ZonedDateTime dateTime, String method,
                         String resource, int status, long bytes, String userAgent) {
    this.ipAddress = ipAddress;
    this.dateTime = dateTime;
    this.method = method;
    this.resource = resource;
    this.status = status;
    this.bytes = bytes;
    this.userAgent = userAgent;
  }

  public String getIpAddress() {
    return ipAddress;
  }

  public ZonedDateTime getDateTime() {
    return dateTime;
  }

  public String getMethod() {
    return method;
  }

  public String getResource() {
    return resource;
  }

  public int getStatus() {
    return status;
  }

  public long getBytes() {
    return bytes;
  }

  public String getUserAgent() {
    return userAgent;
  }

  /**
   * Creates a copy of this record with a different IP address.
   *
   * @param ipAddress new IP address
   * @return new record
   */
  public ApacheLogRecord withIpAddress(String ipAddress) {
    return new ApacheLogRecord(ipAddress, this.dateTime, this.method, this.resource, this.status,
                               this.bytes, this.userAgent);
  }

  /**
   * Creates a copy of this record with a different user agent string.
   *
   * @param userAgent new user agent string
   * @return new record
   */
  public ApacheLogRecord withUserAgent(String userAgent) {
    return new ApacheLogRecord(this.ipAddress, this.dateTime, this.method, this.resource,
                               this.status, this.bytes, userAgent);
  }

  private static final Pattern PARSE_PATTERN = Pattern.compile(
    "^(\\S+) \\S+ \\S+ \\[([^]]+)\\] \"(\\S+) (\\S+) \\S+\" (\\d+) (\\d+) \\S+ \"([^\"]+)\"$"
  );
  static final DateTimeFormatter TIMESTAMP_FORMATTER =
    DateTimeFormatter.ofPattern("dd/MMM/yyyy:HH:mm:ss Z");

  /**
   * Parses a new record from a string.
   *
   * @param logLine line from access log
   * @throws IllegalArgumentException if the line cannot be parsed
   */
  public ApacheLogRecord(String logLine) {
    Matcher m = PARSE_PATTERN.matcher(logLine);
    if (!m.find()) {
      throw new IllegalArgumentException("Line does not match expected pattern");
    }

    ipAddress = m.group(1);
    dateTime = TIMESTAMP_FORMATTER.parse(m.group(2), ZonedDateTime::from);
    method = m.group(3);
    resource = m.group(4);
    status = Integer.parseInt(m.group(5));
    bytes = Long.parseLong(m.group(6));
    userAgent = m.group(7);
  }

  @Override
  public String toString() {
    return String.format("%s %s %s %s %d %d %s", ipAddress, dateTime, method, resource, status,
                         bytes, userAgent);
  }
}
