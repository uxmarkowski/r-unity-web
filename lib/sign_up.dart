import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_list_pick/country_list_pick.dart' as CLP;
import 'package:event_web/sign_in.dart';
import 'package:event_web/sign_verification.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'custom_route.dart';
import 'main.dart';



class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {

  TextEditingController PhoneController=TextEditingController();
  TextEditingController NickNameController=TextEditingController();
  TextEditingController FirstNameController=TextEditingController();
  TextEditingController LastNameController=TextEditingController();
  TextEditingController PromoCodeController=TextEditingController();

  FocusNode PhoneNode=FocusNode();
  FocusNode NickNameNode=FocusNode();
  FocusNode FirstNameNode=FocusNode();
  FocusNode LastNameNode=FocusNode();
  FocusNode PromoCodeNode=FocusNode();

  String Country="US";

  int GenderValue=0;
  bool accept_privacy_policy=true;
  bool LoadBool=false;

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<bool> GetNicknames(name) async{
    bool result=false;
    var nicknamesCollection = await firestore.collection("Nicknames").get();

    await Future.forEach(nicknamesCollection.docs, (doc) {
      if(name.toString().toLowerCase()==doc.id.toString().toLowerCase()) result=true;
    });

    return result;
  }

  Future<bool> CheckUserExist(phone) async{
    setState(() {LoadBool=true;});
    bool func_value=false;

    // print(phone);
    var users_collection=await firestore.collection("UsersCollection").get();
    await Future.forEach(users_collection.docs, (doc) {
      // print(doc.id);

      if(doc.id==phone){
        setState(() {LoadBool=false;});
        // UserMessage("")
        func_value=true;
      }
    });


    setState(() {LoadBool=false;});
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
      appBar: AppBarPro("Sign up"),
      body: GestureDetector(
        onTap: (){
          PhoneNode.hasFocus ? PhoneNode.unfocus() : null;
          NickNameNode.hasFocus ? NickNameNode.unfocus() : null;
          FirstNameNode.hasFocus ? FirstNameNode.unfocus() : null;
          LastNameNode.hasFocus ? LastNameNode.unfocus() : null;
          PromoCodeNode.hasFocus ? PromoCodeNode.unfocus() : null;
        },
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: (MediaQuery.of(context).size.width>800 ? MediaQuery.of(context).size.width/4 : 28),
              vertical: 24
          ),
          height: MediaQuery.of(context).size.height,

          child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 48,),
                      // BigText(AppLocalizations.of(context)!.enter_profile_information),
                      BigText("Enter profile information"),
                      SizedBox(height: 24,),
                      // Text(AppLocalizations.of(context)!.required,style: TextStyle(height: 1.4,fontWeight: FontWeight.w600),),
                      Text("Required",style: TextStyle(height: 1.4,fontWeight: FontWeight.w600),),
                      SizedBox(height: 16,),
                      PhoneFormPro(PhoneController,PhoneNode,"Phone number"),
                      SizedBox(height: 16,),
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            color: Color.fromRGBO(239, 239, 255, 1),
                            borderRadius: BorderRadius.circular(8)
                        ),
                        child: TextFormField(
                          maxLines: null,
                          focusNode: NickNameNode,
                          controller: NickNameController,
                          maxLength: 20,
                          keyboardType: TextInputType.text,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(RegExp("[0-9a-zA-Z]")),
                          ],
                          style: TextStyle(height: 1.4),
                          decoration: InputDecoration(
                            counterText: "",
                            border: InputBorder.none,
                            // hintText: AppLocalizations.of(context)!.nickname,
                            hintText: "Nickname",
                          ),
                        ),
                      ),

                      FormProMinLength(FirstNameController,FirstNameNode,"First name",16,true,""),
                      // FormPro(FirstNameController,FirstNameNode,"First name",16,true,""),

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: Color.fromRGBO(239, 239, 255, 1),
                            borderRadius: BorderRadius.circular(8)
                        ),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: CLP.CountryListPick(
                              appBar: AppBarPro("Country"),
                              theme: CLP.CountryTheme(
                                isShowFlag: true,
                                isShowTitle: true,
                                isShowCode: false,
                                isDownIcon: true,
                                showEnglishName: true,
                                labelColor: Colors.black
                              ),
                              // Set default value
                              initialSelection: '+10',
                              // or
                              // initialSelection: 'US'
                              onChanged: (CLP.CountryCode? code) {
                                print((code!.name ) );
                                print(code.code);
                                print(code.dialCode);
                                print(code.flagUri);

                                Country=code.toCountryStringOnly();
                              },
                              // Whether to allow the widget to set a custom UI overlay
                              useUiOverlay: true,
                              // Whether the country list should be wrapped in a SafeArea
                              useSafeArea: false
                          ),
                        ),
                      ),
                      SizedBox(height: 16,),
                      Container(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<int>(
                          backgroundColor: Color.fromRGBO(239, 239, 255, 1),
                          thumbColor: Color.fromRGBO(196, 196, 241, 1),
                          padding: EdgeInsets.all(2),
                          groupValue: GenderValue,
                          children: {
                            // 0: buildSegment(AppLocalizations.of(context)!.male,GenderValue,0),
                            0: buildSegment("Male",GenderValue,0),
                            // 1: buildSegment(AppLocalizations.of(context)!.female,GenderValue,1),
                            1: buildSegment("Female",GenderValue,1),
                            // 2: buildSegment(AppLocalizations.of(context)!.other,GenderValue,2),
                            2: buildSegment("Other",GenderValue,2),
                          },
                          onValueChanged: (value){
                            setState(() {
                              GenderValue = value!;

                            });

                          },
                        ),
                      ),
                      SizedBox(height: 8),
                      // Text(AppLocalizations.of(context)!.choose_your_gender,style: TextStyle(height: 1.3,color: Colors.black54,fontSize: 12,fontWeight: FontWeight.w400),),
                      Text("Choose your gender in order to see gender-restricted event in R-unity app",style: TextStyle(height: 1.3,color: Colors.black54,fontSize: 12,fontWeight: FontWeight.w400),),
                      SizedBox(height: 24,),
                      // Text(AppLocalizations.of(context)!.optional,style: TextStyle(height: 1.4,fontWeight: FontWeight.w600),),
                      Text("Optional",style: TextStyle(height: 1.4,fontWeight: FontWeight.w600),),
                      SizedBox(height: 16,),
                      // FormProMinLength(LastNameController,LastNameNode,AppLocalizations.of(context)!.last_name,0,true,""),
                      FormPro(LastNameController,LastNameNode,"Last name",0,true,""),
                      SizedBox(height: 16,),
                      // FormProMinLength(PromoCodeController,PromoCodeNode,AppLocalizations.of(context)!.promocode,0,true,""),
                      FormPro(PromoCodeController,PromoCodeNode,"Promocode",0,true,""),
                      SizedBox(height: 24,),
                    ],
                  ),
                  ButtonPro(
                      // AppLocalizations.of(context)!.continuee,
                      "Continue",
                          () async{
                    var user_exist=await CheckUserExist(PhoneController.text);
                    // var user_exist=await CheckUserExist("+"+PhoneController.text);
                    var nickname_exist=await GetNicknames(NickNameController.text);
                    if(user_exist){
                      // UserMessage("User already exist", context);
                      NeedToLoginAccount(context: context);
                    } else if(nickname_exist) {
                      UserMessage("Nickname already exist", context);
                    } else if(!accept_privacy_policy) {
                      UserMessage("You need to accept the privacy policy to continue registration", context);
                    } else if(PhoneController.text.length<6||NickNameController.text.length==0||FirstNameController.text.length==0) {
                      UserMessage("Fill all required value", context);
                    } else {
                      await firestore.collection("Nicknames").doc(NickNameController.text).set({"active":true});

                      final page = SignVerificationPage(nomber: "+"+PhoneController.text, data: {
                        "phone":PhoneController.text,
                        "nickname":NickNameController.text.trim(),
                        "firstname":FirstNameController.text,
                        "lastname":LastNameController.text,
                        "promocode":LastNameController.text,
                        "events":[],
                        "organizer_events":[],
                        "chats":[],
                        "notifications":[],
                        "role":0,
                        "gender":GenderValue,
                        "country":Country,
                        "city":"Los Angeles"
                      },
                        is_sign_in: false,
                      );
                      Navigator.of(context).push(CustomPageRoute(page));
                    }
                  },LoadBool),
                  SizedBox(height: 16,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 24,height: 24,child: Checkbox(value: accept_privacy_policy, onChanged: (value){setState(() {accept_privacy_policy=!accept_privacy_policy;});})),
                      SizedBox(width: 12,),
                      Container(
                        width: 260,

                        child: InkWell(
                          onTap: () async{
                            const url = 'http://r-unity.tilda.ws/privacy_policy';
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                            } else {
                            throw 'Could not launch $url';
                            }
                          },
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(text: "By clicking “continue” you accept our ",style: TextStyle(fontSize: 16,color: Colors.black.withOpacity(0.65),fontWeight: FontWeight.w500),),
                                TextSpan(text: "privacy policy",style: TextStyle(fontSize: 16,color: PrimaryCol,fontWeight: FontWeight.w600),),
                              ],
                            ),
                          ),
                        ))
                    ],
                  ),
                  SizedBox(height: 48,),
                ]
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildSegment(String text,value,const_value){
  return Container(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Text(text,style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(value==const_value ? 0.85 : 0.75),fontWeight: value==const_value ? FontWeight.w700 : FontWeight.w400),),
  );
}

Widget buildSegmentTwo(String text){
  return Container(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Text(text),
  );
}


Widget FormProMinLength(controller,node,hint,margin,textfield,suffix) {

  return Container(
    width: double.infinity,
    margin: EdgeInsets.only(bottom: margin.toDouble()),
    padding: EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
        color: Color.fromRGBO(239, 239, 255, 1),
        borderRadius: BorderRadius.circular(8)
    ),
    child: TextFormField(
      maxLines: null,
      maxLength: 16,

      focusNode: node,
      controller: controller,
      keyboardType: textfield ? TextInputType.text : TextInputType.number,
      style: TextStyle(height: 1.4),
      decoration: InputDecoration(
        hintText: hint,
        counterText: "",
        suffix: Text(suffix,style: TextStyle(fontWeight: FontWeight.w700),),
        border: InputBorder.none,
      ),
    ),
  );
}

Widget FormPro(controller,node,hint,margin,textfield,suffix) {

  return Container(
    width: double.infinity,
    margin: EdgeInsets.only(bottom: margin.toDouble()),
    padding: EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
        color: Color.fromRGBO(239, 239, 255, 1),
        borderRadius: BorderRadius.circular(8)
    ),
    child: TextFormField(
      maxLines: null,
      focusNode: node,
      controller: controller,
      keyboardType: textfield ? TextInputType.text : TextInputType.number,
      style: TextStyle(height: 1.4),
      decoration: InputDecoration(
        hintText: hint,
        suffix: Text(suffix,style: TextStyle(fontWeight: FontWeight.w700),),
        border: InputBorder.none,
      ),
    ),
  );
}

void UserMessage(message,context){
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    duration: Duration(seconds: 3),
    backgroundColor: Colors.red,
  ));
}


void NeedToLoginAccount({required context}) async{


  var result=await showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      // title: Text(AppLocalizations.of(context)!.user_is_already_registered),
      title: Text("User is already registered"),
      // content: Text(AppLocalizations.of(context)!.this_phone_number_has_already),
      content: Text("This phone number has already been registered.Do you want to log in?"),
      actions: <Widget>[
        CupertinoDialogAction(
          // child: Text(AppLocalizations.of(context)!.cancel),
          child: Text("Cancel"),

          onPressed: () => Navigator.of(context).pop(false),
        ),
        CupertinoDialogAction(
          // child: Text(AppLocalizations.of(context)!.sign_in),
          child: Text("Log in"),
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );

  if(result) {

    final page = SignInPage();
    Navigator.of(context).pushAndRemoveUntil(CustomPageRoute(page),(Route<dynamic> route) => false);
  }
}