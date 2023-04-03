import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'smtp.dart';
import 'dart:io';

Future sendMail(String recipient, String key) async {
  final message = Message()
    ..from = Address("authentication@no-repply.com")
    ..recipients = [recipient]
    ..subject = "validate your email"
    ..text = '''
    ${File("bin/template/mail.html").readAsStringSync()}
        
    <script type="text/javascript">
      function script(){
        fetch("http://localhost/api/validate/", {
        method: "POST",
        body: "{'$recipient':'$key'}"
        }).then(open("http://localhost/site/home"));
      }
    </script>
    ''';

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
