// This file is automatically generated, so please do not edit it.
// @generated by `flutter_rust_bridge`@ 2.8.0.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

Future<Uint8List?> newLineChart(
        {required List<double> values,
        required List<String> labels,
        String? title,
        int? width,
        int? height}) =>
    RustLib.instance.api.crateApiChartsApiNewLineChart(
        values: values,
        labels: labels,
        title: title,
        width: width,
        height: height);

Future<Uint8List?> newBarChart(
        {required List<String> labels,
        required List<double> values,
        String? title,
        int? width,
        int? height}) =>
    RustLib.instance.api.crateApiChartsApiNewBarChart(
        labels: labels,
        values: values,
        title: title,
        width: width,
        height: height);

Future<Uint8List?> newGraphChart(
        {required String value, String? title, int? width, int? height}) =>
    RustLib.instance.api.crateApiChartsApiNewGraphChart(
        value: value, title: title, width: width, height: height);

Future<Uint8List?> newMindGraphChart(
        {required String value, String? title, int? width, int? height}) =>
    RustLib.instance.api.crateApiChartsApiNewMindGraphChart(
        value: value, title: title, width: width, height: height);
