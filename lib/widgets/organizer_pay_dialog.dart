import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../sign_up.dart';

Future<dynamic> ShowOrgPayDialog({required context,required widget,required my_nickname}) {
  return showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text("Pay to organizer wallet"),
      content: Column(
        children: [
          SizedBox(height: 16),
          Text("Send money to the organizer and put special text (tap copy button) as a comment so that the organizer can add you to the roster"),
          SizedBox(height: 12,),
          Text("Instruction: "+widget.data['my_wallet_instructions']),
          if(widget.data['my_wallet'].length!=0)...[
            SizedBox(height: 12,),
            Text("Organizer wallet: "+widget.data['my_wallet']),
          ],
          Divider(height: 32,color: Colors.black26,),
          Material(
            color: Color.fromRGBO(0, 0, 0, 0),
            child: InkWell(
              onTap: () async{
                await Clipboard.setData(ClipboardData(text: my_nickname+" | "+widget.data['header'].toString()+" | "+
                    (DateTime.fromMillisecondsSinceEpoch(widget.data['date']).month<10 ? "0"+DateTime.fromMillisecondsSinceEpoch(widget.data['date']).month.toString() : DateTime.fromMillisecondsSinceEpoch(widget.data['date']).month.toString()).toString()+"."+
                    (DateTime.fromMillisecondsSinceEpoch(widget.data['date']).day<10 ? "0"+DateTime.fromMillisecondsSinceEpoch(widget.data['date']).day.toString() : DateTime.fromMillisecondsSinceEpoch(widget.data['date']).day.toString()).toString()
                ));
                UserMessage("Text copied",context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Copy button  ",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
                  Icon(Icons.copy,size: 20,),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          child: Text("OK"),
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        if(widget.data['my_wallet_paylink'].length!=0) ...[
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text("Pay link"),
            onPressed: () async{
              var url = widget.data['my_wallet_paylink'];
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                throw 'Could not launch $url';
              }
            },
          ),
        ],
      ],
    ),
  );
}