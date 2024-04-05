import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_web/dev_test.dart';
import 'package:event_web/sign_in.dart';
import 'package:event_web/sign_up_photo.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'custom_route.dart';



class SignVerificationPage extends StatefulWidget {
  final nomber;
  final data;
  final is_sign_in;
  const SignVerificationPage({Key? key,required this.nomber,required this.data,required this.is_sign_in}) : super(key: key);

  @override
  State<SignVerificationPage> createState() => _SignVerificationPageState();
}

class _SignVerificationPageState extends State<SignVerificationPage> {

  TextEditingController PhoneController=TextEditingController();
  TextEditingController NumberController=TextEditingController();
  FocusNode FocussNode=FocusNode();

  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String ErroeMessage="";
  String verificationIdd="";

  var RemainTime=60;
  var IsUserExist=false;
  late PhoneAuthCredential Usercredential;

  bool IsCodeTrue=false;
  bool didGetFirstCode=false;
  bool didGetAnotherCode=false;
  bool LoadBool=false;



  void SendFirstCode() async{


    print("Смс");
    var otpFieldVisibility=false;

    await FirebaseMessaging.instance.requestPermission();

    await _auth.verifyPhoneNumber(
      phoneNumber: widget.nomber,
      verificationCompleted: (PhoneAuthCredential credential) async{
        print("Complete");
      },

      verificationFailed: (FirebaseAuthException e) {
        print(" e "+e.toString());
      },

      codeSent: (String verificationId, int? resendToken) async{

        print("CodeSent +vid"+verificationId+" +rstk"+resendToken.toString());

        String smsCode = NumberController.text;
        verificationIdd=verificationId;
        otpFieldVisibility = true;
        Usercredential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);

      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print('TimeOut');
      },

    );

    setState(() {
      ErroeMessage="";
      didGetAnotherCode=true;
      RemainTime=60;
      didGetFirstCode=true;
    });

    for(int i = 0;i<60;i++) {
      RemainTime=RemainTime-1;

      await Future.delayed(Duration(seconds: 1));
      print("RemainTime "+RemainTime.toString());
      setState(() {

      });
    }


    setState(() {
      RemainTime=60;
      NumberController.clear();
      didGetAnotherCode=false;
    });

  }

  void GoLogin() async{
    setState(() {
      LoadBool=true;
    });

    _auth.signOut();

    var UserCollection=await firestore.collection("UsersCollection").get();
    // final allUsersData = UserCollection.docs.map((doc) => doc.data()).toList();

    await Future.forEach(UserCollection.docs, (user_doc) {
      if(user_doc.id==(widget.nomber)){
        IsUserExist=true;
        print("Юзер найден");
      }
    });
    // allUsersData.forEach((users) {
    //   if(users['phone']==(widget.nomber)){
    //     IsUserExist=true;
    //     print("Юзер найден");
    //   }
    // });

    print("Вход");
    Usercredential = PhoneAuthProvider.credential(smsCode: NumberController.text, verificationId: verificationIdd);

    if(IsUserExist==false) {

      try {
        await _auth.signInWithCredential(Usercredential);
      } on FirebaseAuthException catch (e) {
        print('Failed with error code: ${e.code}');
        print("ee " + e.message.toString());
        setState(() {
          ErroeMessage = e.message.toString();
        });
        if(e.message.toString()=="The SMS verification code used to create the phone auth credential is invalid. Please resend the verification code SMS and be sure to use the verification code provided by the user."){
          setState(() {
            ErroeMessage = "Incorrect code. Please try again";
          });
        }
      }

      if (_auth.currentUser == null) {
        print("Не получилось");
        setState(() {
          LoadBool=false;
        });
      } else {
        print("Получилось");

        await firestore.collection("UsersCollection").doc(widget.nomber).set({
          "phone": widget.nomber,
          "nickname": widget.data==null ? "":widget.data['nickname'],
          "firstname": widget.data==null ? "":widget.data['firstname'],
          "lastname": widget.data==null ? "":widget.data['lastname'],
          "avatar_link":"https://mygardenia.ru/uploads/pers1.jpg",
          "events":[],
          "organizer_events":[],
          "chats":[],
          "notifications":[],
          "chat_requests":[],
          "role":0,
          "verified":false,
          "instagram":"",
          "about":"",
          "gender":widget.data['gender'],
          "country":widget.data['country'],
          "balance":0,
          "show_events_for_friends_only":false,
          "admin":false,
          "friends":[],
        });

        await firestore.collection("UsersCollection").doc(widget.nomber).collection("Notifications").add({
          "title":"Welcome",
          "title_rus":"Добро пожаловать",
          "photo_link": "https://images.unsplash.com/photo-1527529482837-4698179dc6ce?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTJ8fHBhcnR5fGVufDB8fDB8fHww",
          "type":"welcome_notification",
          "check":false,
          "date":DateTime.now().millisecondsSinceEpoch
        });


        final page = MyEventList(doc_id: "",);
        Navigator.of(context).push(CustomPageRoute(page));

        // Navigator.push(context, MaterialPageRoute(builder: (context) => UserNameAddPage()));
      };
    } else {

      try {
        await _auth.signInWithCredential(Usercredential);
      } on FirebaseAuthException catch (e) {
        print('Failed with error code: ${e.code}');
        print("ee " + e.message.toString());
        setState(() {
          ErroeMessage = e.message.toString();
        });
        await Future.delayed(Duration(seconds: 5));
        setState(() {
          ErroeMessage = "";
        });
      }

      if (_auth.currentUser == null) {
        setState(() {
          LoadBool=false;
        });
      } else {


        final page = MyEventList(doc_id: "");
        Navigator.of(context).push(CustomPageRoute(page));

      };
      setState(() {
        LoadBool=false;
      });

    }
  }

  @override
  void initState() {

    SendFirstCode();

    // TODO: implement initState
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarPro("Sign in"),
      // appBar: AppBarPro("Sign in"),
      body: GestureDetector(
        onTap: (){
          FocussNode.unfocus();
        },
        child: Container(
          color: Colors.white,
          height: MediaQuery.of(context).size.height-100,
          padding: EdgeInsets.symmetric(
              horizontal: (MediaQuery.of(context).size.width>800 ? MediaQuery.of(context).size.width/4 : 28),
              vertical: 24
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    SizedBox(height: 56,),
                    // BigText(AppLocalizations.of(context)!.enter_code),
                    BigText("Enter code"),
                    SizedBox(height: 8,),
                    // Center(child: Text(ErroeMessage.length==0 ? AppLocalizations.of(context)!.we_have_sent_you+"\n"+widget.nomber : AppLocalizations.of(context)!.we_have_sent_you+" "+ErroeMessage,textAlign: TextAlign.center,style: TextStyle(height: 1.4,color: ErroeMessage.length==0 ? Colors.black : Colors.red),)),
                    Center(child: Text(ErroeMessage.length==0 ? "We have sent you an SMS with the code to "+widget.nomber : ErroeMessage,textAlign: TextAlign.center,style: TextStyle(height: 1.4,color: ErroeMessage.length==0 ? Colors.black : Colors.red),)),
                    SizedBox(height: 24,),
                    Container(
                      height: 56,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Container(
                            padding: EdgeInsets.only(top: NumberController.text.length>=1 ?  0:6),
                            child: PinCode(NumberController)
                          ),
                          Container(
                            color: Colors.red.withOpacity(0),
                            child: Opacity(
                              child: TextFormField(
                                  controller: NumberController,
                                  keyboardType: TextInputType.number,
                                  autofocus: true,
                                  maxLength: 6,
                                  focusNode: FocussNode,
                                  onChanged: (value){setState(() {});
                                  if(NumberController.text.length==6){
                                    GoLogin();

                                  }
                                  }
                              ),
                              opacity: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                TextButton(
                    onPressed: (){
                      if(RemainTime==60){
                        SendFirstCode();
                      }
                    // }, child: RemainTime==60 ? Text(AppLocalizations.of(context)!.resend_code,style: TextStyle(color: PrimaryCol,fontWeight: FontWeight.w700,fontSize: 16),) : Text( AppLocalizations.of(context)!.wait+" "+RemainTime.toString(),style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w500,fontSize: 16),)
                    }, child: RemainTime==60 ? Text("Resend code",style: TextStyle(color: PrimaryCol,fontWeight: FontWeight.w700,fontSize: 16),) : Text( "Wait "+RemainTime.toString(),style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w500,fontSize: 16),)
                )
              ]
          ),
        ),
      ),
    );
  }
}


Widget PinCode(NumberController,){
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      SizedBox(width: 12,),
      if(NumberController.text.length>=1) ...[
        Container(
          width: 24,
          height: 36,
          child: Center(
              child: Text(NumberController.text.substring(0,1),style: TextStyle(fontSize: 24,fontWeight: FontWeight.w700),)
          ),
        ),
      ] else ...[
        Container(
          height: 24,
          width: 24,
          decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(40)
          ),
        ),
      ],
      if(NumberController.text.length>=2) ...[
        Container(
          width: 24,
          height: 36,
          child: Center(
              child: Text(NumberController.text.substring(1,2),style: TextStyle(fontSize: 24,fontWeight: FontWeight.w700),)
          ),
        ),
      ]  else ...[
        Container(
          height: 24,
          width: 24,
          decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(40)
          ),
        ),
      ],
      if(NumberController.text.length>=3) ...[
        Container(
          width: 24,
          height: 36,
          child: Center(
              child: Text(NumberController.text.substring(2,3),style: TextStyle(fontSize: 24,fontWeight: FontWeight.w700),)
          ),
        ),
      ] else ...[
        Container(
          height: 24,
          width: 24,
          decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(40)
          ),
        ),
      ],
      if(NumberController.text.length>=4) ...[
        Container(
          width: 24,
          height: 36,
          child: Center(
              child: Text(NumberController.text.substring(3,4),style: TextStyle(fontSize: 24,fontWeight: FontWeight.w700),)
          ),
        ),
      ] else ...[
        Container(
          height: 24,
          width: 24,
          decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(40)
          ),
        ),
      ],
      if(NumberController.text.length>=5) ...[
        Container(
          width: 24,
          height: 36,
          child: Center(
              child: Text(NumberController.text.substring(4,5),style: TextStyle(fontSize: 24,fontWeight: FontWeight.w700),)
          ),
        ),
      ] else ...[
        Container(
          height: 24,
          width: 24,
          decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(40)
          ),
        ),
      ],
      if(NumberController.text.length>=6) ...[
        Container(
          width: 24,
          height: 36,
          child: Center(
              child: Text(NumberController.text.substring(5,6),style: TextStyle(fontSize: 24,fontWeight: FontWeight.w700),)
          ),
        ),
      ] else ...[
        Container(
          height: 24,
          width: 24,
          decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(40)
          ),
        ),
      ],
      SizedBox(width: 12,),
    ],
  );
}