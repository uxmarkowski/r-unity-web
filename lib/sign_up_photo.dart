import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_web/dev_test.dart';
import 'package:event_web/sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import 'custom_route.dart';



class SignUpPhotoPage extends StatefulWidget {
  final nomber;
  final type;
  const SignUpPhotoPage({Key? key,required this.nomber,required this.type}) : super(key: key);

  @override
  State<SignUpPhotoPage> createState() => _SignUpPhotoPageState();
}

class _SignUpPhotoPageState extends State<SignUpPhotoPage> {

  final storageRef = FirebaseStorage.instance.ref();
  TextEditingController numbercontroller=TextEditingController(); // Контролер номера телефона
  final ImagePicker _picker = ImagePicker();
  late XFile? image;
  bool image_load=false;

  bool WaitForNextStep=false;
  FirebaseFirestore firestore = FirebaseFirestore.instance;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarPro(widget.type=="Sign" ? "Sign up" : "Edit photo"),
      // appBar: AppBarPro(widget.type=="Sign" ? "Sign up" : "Edit photo"),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height-100,
        padding: EdgeInsets.all(24),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 24,),
                  // BigTextCenter((widget.type=="Sign" ? AppLocalizations.of(context)!.add : AppLocalizations.of(context)!.edit)+" "+AppLocalizations.of(context)!.profile_photo,),
                  BigTextCenter((widget.type=="Sign" ? "Add" : "Edit")+" profile photo"),
                  SizedBox(height: 12,),
                  // Text(AppLocalizations.of(context)!.load_photo_from_gallery,style: TextStyle(height: 1.4,fontWeight: FontWeight.w600),textAlign: TextAlign.center,),
                  Text("Load photo from gallery or stay\n this empty",style: TextStyle(height: 1.4,fontWeight: FontWeight.w600),textAlign: TextAlign.center,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 24,),
                      Stack(
                        children: [
                          Center(
                            child: SvgPicture.asset("lib/assets/AddPhotoBackLine.svg")
                          ),
                          if(image_load&&image!=null) ...[
                            Center(
                              child: Container(
                                margin: EdgeInsets.only(top: 16),
                                height: 228,
                                width: 228,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(240),
                                    color: Colors.black,
                                    image: DecorationImage(
                                        image:  FileImage(File(image!.path)),
                                        fit: BoxFit.cover,
                                        opacity: 0.6
                                    )
                                ),
                              ),
                            ),
                          ],
                          Center(
                            child: Container(
                              margin: EdgeInsets.only(top: 16),
                              height: 228,
                              width: 228,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(240),
                                // image: DecorationImage(
                                //   image: Image.file(file)
                                // )
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    InkWell(
                                      onTap: () async{

                                        if(image_load&&image!=null){

                                          File(image!.path).delete();
                                          image = await _picker.pickImage(source: ImageSource.gallery);
                                          image_load=true;
                                          setState(() {

                                          });

                                        } else {

                                          try {
                                            image = await _picker.pickImage(source: ImageSource.gallery);
                                            image_load=true;
                                            setState(() {

                                            });
                                          } on PlatformException catch  (e) {
                                            print("Erroe");
                                            var result=await showCupertinoDialog(
                                              context: context,
                                              builder: (context) => CupertinoAlertDialog(
                                                title: Text("Access to your photos"),
                                                content: Text("Unfortunately, you have blocked the application from accessing photos. A photo is not required for the application to work, but if you change your mind, you need to go to settings and add it"),
                                                actions: <Widget>[
                                                  CupertinoDialogAction(
                                                    child: Text("Stay"),

                                                    onPressed: () => Navigator.of(context).pop(false),
                                                  ),
                                                  CupertinoDialogAction(
                                                    child: Text("Add"),
                                                    isDefaultAction: true,
                                                    onPressed: () => Navigator.of(context).pop(true),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if(result){
                                              AppSettings.openAppSettings().then((value) => setState((){}));
                                            }


                                          }

                                        }


                                      },
                                      child: Container(
                                        height: 48,
                                        width: image_load ? 174 : 144,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(48)
                                        ),
                                        child: Center(
                                          // child: image_load ? Text(AppLocalizations.of(context)!.change_photo,style: TextStyle(color: Colors.black,fontWeight: FontWeight.w600),) : Text(AppLocalizations.of(context)!.add_photo,style: TextStyle(color: Colors.black,fontWeight: FontWeight.w600),),
                                          child: image_load ? Text("Change photo",style: TextStyle(color: Colors.black,fontWeight: FontWeight.w600),) : Text("Add photo",style: TextStyle(color: Colors.black,fontWeight: FontWeight.w600),),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                  // Кнопка продолжить
                  // Center(
                  //   child: Column(
                  //     children: [
                  //       // Container(
                  //       //   child: Text("I'll do it later",textAlign: TextAlign.center,),
                  //       //   width: 300,
                  //       // ),
                  //       // SizedBox(height: 16),
                  //       if(image_load) ...[
                  //         InkWell(
                  //           onTap: () async{
                  //
                  //             setState(() {
                  //               WaitForNextStep=true;
                  //             });
                  //             print("Загрузка фото");
                  //             FirebaseAuth _auth = FirebaseAuth.instance;
                  //             var Avatar_Path="avatars/avatar_"+_auth.currentUser!.phoneNumber.toString().substring(1)+".jpg";
                  //             final mountainsRef = storageRef.child(Avatar_Path);
                  //             File file = File(image!.path);
                  //             await mountainsRef.putFile(file);
                  //             var urr=await mountainsRef.getDownloadURL();
                  //
                  //             await firestore.collection("UsersCollection").doc(_auth.currentUser?.phoneNumber).update({
                  //               "avatar_path": Avatar_Path.toString(),
                  //               "avatar_link": urr.toString(),
                  //             });
                  //
                  //             print("urr "+urr.toString());
                  //
                  //             Navigator.pop(context);
                  //           },
                  //           child: Container(
                  //             height: 56,
                  //             margin: EdgeInsets.only(bottom: 24),
                  //             width: double.infinity,
                  //             decoration: BoxDecoration(
                  //                 color: Color.fromRGBO(30, 35, 30, 1),
                  //                 borderRadius: BorderRadius.circular(12)
                  //             ),
                  //             child: Center(
                  //               child: WaitForNextStep ? CupertinoActivityIndicator(color: Colors.white,) : Text("Сохранить",style: TextStyle(color: Colors.white),),
                  //             ),
                  //           ),
                  //         ),
                  //       ] else ...[
                  //
                  //       ]
                  //     ],
                  //   ),
                  // )

                ],
              ),
              if(image_load) ...[
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: ButtonPro(
                      // AppLocalizations.of(context)!.continuee,
                      "Continue",
                          () async{

                    setState(() {
                      WaitForNextStep=true;
                    });
                    print("Загрузка фото");
                    FirebaseAuth _auth = FirebaseAuth.instance;
                    var Avatar_Path="avatars/avatar_"+_auth.currentUser!.phoneNumber.toString().substring(1)+".jpg";
                    final mountainsRef = storageRef.child(Avatar_Path);
                    File file = File(image!.path);
                    await mountainsRef.putFile(file);
                    var urr=await mountainsRef.getDownloadURL();

                    await firestore.collection("UsersCollection").doc(_auth.currentUser?.phoneNumber).update({
                      "avatar_path": Avatar_Path.toString(),
                      "avatar_link": urr.toString(),
                    });

                    print("urr "+urr.toString());

                    if(widget.type=="Sign"){
                      final page = MyEventList(doc_id: "",);
                      Navigator.of(context).push(CustomPageRoute(page));
                    } else {
                      Navigator.pop(context);
                    }

                  },WaitForNextStep),
                ),
              ]
            ]
        ),
      ),
    );
  }
}
