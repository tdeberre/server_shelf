import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'smtp.dart';
import 'dart:io';

Future sendMail(String recipient, String key) async {
  final file = File("bin/template/private/mail.html").readAsStringSync();
  final splited = file.split("{here}");
  String text = "${splited[0]}$recipient/$key${splited[1]}";
  final message = Message()
    ..from = Address("authentication@no-repply.com")
    ..recipients = [recipient]
    ..subject = "validate your email"
    ..text = text;

  final smtpServer = SmtpServer(
    'smtp-relay.sendinblue.com',
    port: 587,
    username: usernameSMTP,
    password: passwordSMTP,
  );
  try {
    send(message, smtpServer);
  } catch (e) {
    print(e);
  }
}
