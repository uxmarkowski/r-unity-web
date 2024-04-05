import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_web/sign_up.dart';
import 'package:event_web/sign_verification.dart';
import 'package:event_web/sign_up.dart';
import 'package:event_web/sign_verification.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'custom_route.dart';
import 'main.dart';



class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  TextEditingController PhoneController=TextEditingController();
  FocusNode PhoneNode=FocusNode();

  bool wait_bool=false;

  Future<bool> CheckUserExist(phone) async{
    setState(() {wait_bool=true;});
    bool func_value=false;

    // print(phone);
    var users_collection=await firestore.collection("UsersCollection").get();
    await Future.forEach(users_collection.docs, (doc) {
      // print(doc.id);

      if(doc.id==phone){
        setState(() {wait_bool=false;});
        // UserMessage("")
        func_value=true;
      }
    });


    setState(() {wait_bool=false;});
    return func_value;
  }

  @override
  void initState() {
    PhoneController.text="1";
    // setState(() {
    //
    // });
    // TODO: implement initState
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarPro("Sign in"),
      body: Container(
        padding: EdgeInsets.symmetric(
          horizontal: (MediaQuery.of(context).size.width>800 ? MediaQuery.of(context).size.width/4 : 28),
          vertical: 24
        ),
        height: MediaQuery.of(context).size.height,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  SizedBox(height: 56,),
                  // BigText(AppLocalizations.of(context)!.sign_in_with_phone),
                  BigText("Sign in with phone"),
                  SizedBox(height: 8,),
                  // Center(child: Text(AppLocalizations.of(context)!.please_enter_phone,textAlign: TextAlign.center,style: TextStyle(height: 1.4),)),
                  Center(child: Text("Please enter your phone number",textAlign: TextAlign.center,style: TextStyle(height: 1.4),)),
                  SizedBox(height: 24,),
                  PhoneFormPro(PhoneController,PhoneNode,"Phone number"),
                ],
              ),
              SizedBox(height: 24,),
              Container(
                margin: EdgeInsets.only(bottom: 12),
                child: ButtonPro(
                    "Continue",
                        () async{
                  var user_exit=await CheckUserExist("+"+PhoneController.text);
                  if(user_exit){
                    print("User exist");
                    final page = SignVerificationPage(nomber: "+"+PhoneController.text,data: null,is_sign_in: true,);
                    Navigator.of(context).push(CustomPageRoute(page));
                  } else {
                    // UserMessage("User with this nomber don't exist", context);
                    NeedToRegisterAccount(context: context);

                    // final page = SignUpPage();
                    // Navigator.of(context).push(CustomPageRoute(page));
                  }

                },wait_bool),
              )
            ]
        ),
      ),
    );
  }
}





Widget ButtonPro(title,onTap,wait) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
        primary: PrimaryCol,
        minimumSize: const Size.fromHeight(52), // NEW
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
    ),
    onPressed: onTap,
    child: wait ? CupertinoActivityIndicator(color: Colors.white,) : Text(title,style: TextStyle(fontSize: 16,color: Colors.white,fontWeight: FontWeight.w600),textAlign: TextAlign.center,),
  );
}



PreferredSizeWidget AppBarPro(title) {
  return AppBar(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 1,
    title: Text(title,style: TextStyle(color: Colors.black,fontWeight: FontWeight.w600),),
    centerTitle: true,
  );
}


void NeedToRegisterAccount({required context}) async{


  var result=await showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      // title: Text(AppLocalizations.of(context)!.no_such_user),
      title: Text("No such user"),
      // content: Text(AppLocalizations.of(context)!.this_phone_number_is_not),
      content: Text("This phone number is not registered. Want to register?"),
      actions: <Widget>[
        CupertinoDialogAction(
          // child: Text(AppLocalizations.of(context)!.cancel),
          child: Text("Cancel"),

          onPressed: () => Navigator.of(context).pop(false),
        ),
        CupertinoDialogAction(
          // child: Text(AppLocalizations.of(context)!.register),
          child: Text("Register"),
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );

  if(result) {

    final page = SignUpPage();
    Navigator.of(context).pushAndRemoveUntil(CustomPageRoute(page),(Route<dynamic> route) => false);
  }
}


Widget PhoneFormPro(controller,node,hint) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
        color: Color.fromRGBO(239, 239, 255, 1),
        borderRadius: BorderRadius.circular(8)
    ),
    child: TextFormField(
      focusNode: node,
      keyboardType: TextInputType.phone,
      controller: controller,
      decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          prefixIcon: Icon(CupertinoIcons.plus,size: 16,color: Colors.black,),
          prefixIconConstraints: BoxConstraints(minWidth: 24)
      ),
      onChanged: (value){
        // var text=(controller as TextEditingController).text;
        // if(text.length>=1){
        //   (controller as TextEditingController).text="+"+(controller as TextEditingController).text;
        // }
      },
    ),
  );
}


Widget BigText(title) {
  return Text(title,style: TextStyle(fontSize: 24,fontWeight: FontWeight.w600,color: Colors.black),);
}

Widget BigTextCenter(title) {
  return Center(
      child: Text(title,style: TextStyle(fontSize: 24,fontWeight: FontWeight.w600,color: Colors.black,),textAlign: TextAlign.center,)
  );
}