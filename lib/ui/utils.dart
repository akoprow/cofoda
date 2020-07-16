import 'package:flutter/material.dart';

const Widget defaultPlaceholder = Center(child: CircularProgressIndicator());

Widget showFuture<T>(Future<T> future, Widget Function(T) display, {Widget placeholder = defaultPlaceholder}) =>
    FutureBuilder(
        future: future,
        builder: (context, AsyncSnapshot<T> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              if (snapshot.hasError) {
                print('Future error: ${snapshot.error}');
                return Container();
              } else {
                return display(snapshot.data);
              }
              break;
            default:
              return placeholder;
          }
        });
