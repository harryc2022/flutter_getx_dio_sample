import 'dart:math';
import 'dart:convert';

import 'dart:typed_data';

class UUID {
  static List<String> stringArray = [
    "4a9a",
    "e40b",
    "f98a",
    "012d",
    "d8c8",
    "5788",
    "bbdf",
    "2a68",
    "f7ae",
    "db73",
    "425f",
    "8e31",
    "be56",
    "154f",
    "6eae",
    "4305",
    "1cde",
    "c9b9",
    "6c23",
    "afd3",
    "ecfb",
    "2bbf",
    "4ef4",
    "3e02",
    "c0cf",
    "ea3e",
    "f605",
    "29ee",
    "18b8",
    "24c4",
    "0c5f",
    "bd6d",
    "d3f8",
    "f4f3",
    "a01f",
    "cab8",
    "9b3e",
    "6f2a",
    "f475",
    "a0e9",
    "59b3",
    "c767",
    "2545",
    "6306",
    "a43a",
    "c2ba",
    "1907",
    "9475",
    "4182",
    "5364",
    "3518",
    "fc39",
    "8f1b",
    "5131",
    "6fc4",
    "2dc7",
    "054c",
    "f2f6",
    "f898",
    "f260",
    "b3b8",
    "4da6",
    "389d",
    "43a0",
    "8d47",
    "3320",
    "1949",
    "ccb9",
    "deae",
    "81e1",
    "2d1c",
    "1ea5",
    "1c99",
    "ab84",
    "803d",
    "a14c",
    "631b",
    "5aa6",
    "6b43",
    "4b74",
    "b53e",
    "1ae5",
    "57bd",
    "789a",
    "012b",
    "7069",
    "4e4b",
    "85b5",
    "9092",
    "365b",
    "1ab2",
    "60a4",
    "f47a",
    "9d32",
    "2d5c",
    "fb73",
    "9197",
    "921d",
    "f079",
    "41e0"
  ];

  static List<String> base = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f'
  ];

  static Random mR = new Random();

  static String converRef(String input, int seconds) {
    List<String> refBuf = new List<String>.generate(input.length,(i)
    {
      return "";
    }
    );
    int charIndex = 0;
    int tmpIndex = seconds % 100;
    do {
      int toIndex = strtol(input[charIndex]);
      //print("toIndex$toIndex");
      int index = ((toIndex + tmpIndex) & 0xf);
      refBuf[charIndex] = base[index];
      charIndex++;
    } while (charIndex < input.length);
    return refBuf.join();
  }

  static String makeRaw64String() {
    int len = 64 >> 2;
    List<String> sb = new List<String>.generate(len,(i)
    {
      return "";
    }
    );
    for (int i = 0; i < len; i++) {
      int randomIndex = mR.nextInt(0x5a);
      sb[i] = stringArray[randomIndex];
      // print("makeRaw64String$sb");
    }
    return sb.join();
  }

  static int strtol(String oc) {
    for (int i = 0; i < base.length; i++) {
      if (oc == base[i]) return i;
    }
    return 0;
  }

  static String random(int seconds) {
    String rawRef = makeRaw64String();
    //print("random-->$rawRef");
    return converRef(rawRef, seconds);
  }

  static int hash(String uuid) {
    Uint8List bs = new Utf8Encoder().convert(uuid);
    int code = 0;
    for (int b in bs) {
      code += b & 0xf;
    }
    //print("hash-->$code");
    return code;
  }
}
