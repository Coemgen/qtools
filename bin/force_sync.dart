import 'dart:io';
import 'package:path/path.dart';

main(List<String> args) {
  if (args.length != 1) {
    print('usage: PATH_TO_QCodefag.github.io');
    return;
  }

  var repoDir = absolute(args[0]);
  var sinkDir = join(repoDir, 'data');

  print(repoDir);
  print(sinkDir);
  updateAmazonSiteFile('qresearchTrip8chanPosts.json', sinkDir);
  updateAmazonSiteFile('greatawakeningTrip8chanPosts.json', sinkDir);
}

updateAmazonSiteFile(String fileName, String sinkDir) {
  Process.runSync('aws', ['s3', 'cp', fileName, 's3://aws-website-qposts-gg8qo/data/$fileName'], workingDirectory: sinkDir);
}