import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {

  static VoidCallback defErr = () {

  };

  static VoidCallback defSuc = () {

  };

  // static Future<bool> check(PermissionType type, {VoidCallback onSuc, VoidCallback onErr, String errMsg}) async {
  //   bool flag = false;
  //   Permission permission = convertType(type);
  //   PermissionStatus status = await permission.status;
  //   if (status.isGranted) {
  //     onSuc != null ? onSuc() : defSuc();
  //     flag = true;
  //   }
  //   else if (status.isUndetermined) {
  //     PermissionStatus p = await permission.request();
  //     if (p.isGranted) {
  //       onSuc != null ? onSuc() : defSuc();
  //       flag = true;
  //     }
  //     else {
  //       showErr(onErr: onErr, errMsg: errMsg);
  //     }
  //   }
  //   else if (status.isDenied || status.isPermanentlyDenied) {
  //     PermissionStatus p = await permission.request();
  //     if (p.isGranted) {
  //       onSuc != null ? onSuc() : defSuc();
  //       flag = true;
  //     }
  //     else {
  //       showErr(onErr: onErr, errMsg: errMsg);
  //     }
  //   }
  //   else {
  //     showErr(onErr: onErr, errMsg: errMsg);
  //   }
  //   return flag;
  // }

  // static void showErr({VoidCallback onErr, String errMsg}) {
  //   showToastCommon(errMsg ?? '请授予该权限，否则将影响一些功能的使用');
  //   onErr ?? defErr();
  // }

  static Permission convertType(PermissionType type) {
    Permission p;
    switch (type) {
      case PermissionType.calendar:
        p = Permission.calendar;
        break;
      case PermissionType.camera:
        p = Permission.camera;
        break;
      case PermissionType.contacts:
        p = Permission.contacts;
        break;
      case PermissionType.location:
        p = Permission.location;
        break;
      case PermissionType.locationAlways:
        p = Permission.locationAlways;
        break;
      case PermissionType.locationWhenInUse:
        p = Permission.locationWhenInUse;
        break;
      case PermissionType.mediaLibrary:
        p = Permission.mediaLibrary;
        break;
      case PermissionType.microphone:
        p = Permission.microphone;
        break;
      case PermissionType.phone:
        p = Permission.phone;
        break;
      case PermissionType.photos:
        p = Permission.photos;
        break;
      case PermissionType.photosAddOnly:
        p = Permission.photosAddOnly;
        break;
      case PermissionType.reminders:
        p = Permission.reminders;
        break;
      case PermissionType.sensors:
        p = Permission.sensors;
        break;
      case PermissionType.sms:
        p = Permission.sms;
        break;
      case PermissionType.speech:
        p = Permission.speech;
        break;
      case PermissionType.storage:
        p = Permission.storage;
        break;
      case PermissionType.ignoreBatteryOptimizations:
        p = Permission.ignoreBatteryOptimizations;
        break;
      case PermissionType.notification:
        p = Permission.notification;
        break;
      case PermissionType.accessMediaLocation:
        p = Permission.accessMediaLocation;
        break;
      case PermissionType.activityRecognition:
        p = Permission.activityRecognition;
        break;
      default:
        p = Permission.unknown;
    }
    return p;
  }
}

enum PermissionType {
  calendar,
  camera,
  contacts,
  location,
  locationAlways,
  locationWhenInUse,
  mediaLibrary,
  microphone,
  phone,
  photos,
  photosAddOnly,
  reminders,
  sensors,
  sms,
  speech,
  storage,
  ignoreBatteryOptimizations,
  notification,
  accessMediaLocation,
  activityRecognition,
  unknown
}
