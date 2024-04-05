import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_web/dev_test.dart';
import 'package:event_web/sign_in.dart';
import 'package:event_web/sign_up.dart';
import 'package:event_web/widgets/organizer_pay_dialog.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as GM;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:video_player/video_player.dart';

import 'card_form_screen.dart';
import 'custom_route.dart';
import 'dev_test.dart';



class EventPage extends StatefulWidget {
  final data;
  const EventPage({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  int? groupValue = 0;
  int FinalGroupValue = 0;
  int peoples_length=0;
  int after_discount_price_percent=100;
  bool show_sign_popup=false;
  bool pay_with_my_wallet=false;



  var my_nickname="";
  var RussianLanguage=false;

  var EventData=Map();


  var EventUsersListManual=[]; var EventUsersList=[]; var EventUsersWaitList=[]; var EventUsersInviteList=[]; var EventOrganizerList=[]; var EventOrganizerListData=[]; var EventUsersListData=[]; var MessageList=[];

  bool IsUserIn=false;
  bool IAmOrganizer=false;
  bool IAmAdmin=false;
  bool IAmInWaitList=false;
  bool IAmInvited=false;
  bool show_buttons=false;
  bool join_wait_bool=false;
  bool add_friend_wait_bool=false;
  bool russian_language=false;

  TextEditingController MessageController = TextEditingController();
  FocusNode MessageNode = FocusNode();
  late StreamSubscription stream;
  late StreamSubscription event_data_stream;

  var RightPromoCode="";


  void SendMessage(Message) async{firestore.collection("Events").doc(widget.data['doc_id']).collection("Messages").add(Message);}


  void GetAllMessage() async{
    MessageList=[];

    var MessagesCollection=await firestore.collection("Events").doc(widget.data['doc_id']).collection("Messages").get();
    print("Получаем сообщения "+widget.data['doc_id'].toString());
    await Future.forEach(MessagesCollection.docs, (message) => MessageList.add(message.data()));
    // MessageList=messages.data()!['messages'] as List;
    MessageList.sort((a,b){
      return DateTime.fromMillisecondsSinceEpoch(a["time"]).compareTo(DateTime.fromMillisecondsSinceEpoch(b["time"]));
    });
    setState(() { });
    // UpDateMessage(messages);
  }


  void JoinFree() async{
    await firestore.collection("UsersCollection").doc(_auth.currentUser!.phoneNumber).collection("Events").doc(widget.data['doc_id']).set({"active":true});
    await firestore.collection("Events").doc(widget.data['doc_id']).collection("Users").doc(_auth.currentUser!.phoneNumber).set({"active":true});
    await firestore.collection("Events").doc(widget.data['doc_id']).update({"peoples":peoples_length+1,}); // Добавляем юзера в список
  }

  void PayForOrganizerWallet()async {

    if(IAmInWaitList){
      await firestore.collection("Events").doc(widget.data['doc_id']).collection("WaitList").doc(_auth.currentUser!.phoneNumber).delete();
      setState(() { IAmInWaitList=false; });
      ScaffoldMessaLong("You have been removed from the waiting list",context);
    } else {
      var result=await ShowOrgPayDialog(context: context, widget: widget, my_nickname: my_nickname,);
      if(result) {
        await firestore.collection("Events").doc(widget.data['doc_id']).collection("WaitList").doc(_auth.currentUser!.phoneNumber).set({"active":"true"});
        setState(() { IAmInWaitList=true; });
        ScaffoldMessaLong("Thank you for your application, after payment wait for the organizer to accept you to the event. "+"You will receive a notification in mobile app",context);
      }
    }



  }




  void GetEventUsersCollection() async{
    EventUsersListData=[]; EventOrganizerList=[]; EventOrganizerListData=[]; EventUsersList=[]; EventUsersListManual=[]; EventUsersWaitList=[]; var EventUsersInviteList=[];
    
    if(2==3){setState(() {IAmAdmin=true;});}
    var EventDoc=await firestore.collection("Events").doc(widget.data['doc_id']).get();
    setState(() {peoples_length=EventDoc.data()!['peoples']; });
    var UsersCollection=await firestore.collection("Events").doc(widget.data['doc_id']).collection("Users").get();
    var PromoUserCollection=await firestore.collection("Events").doc(widget.data['doc_id']).collection("PromoUsers").get();
    var UsersWaitListCollection=await firestore.collection("Events").doc(widget.data['doc_id']).collection("WaitList").get();
    var UsersInvitedUsersCollection=await firestore.collection("Events").doc(widget.data['doc_id']).collection("InvitedUsers").get();
    var UsersOrganizersCollection=await firestore.collection("Events").doc(widget.data['doc_id']).collection("Organizers").get();

    
    await Future.forEach(UsersCollection.docs, (UserDoc) {UserDoc.data()['active'] ? EventUsersList.add(UserDoc.id) : EventUsersListManual.add(UserDoc.data());  });
    await Future.forEach(UsersOrganizersCollection.docs, (UserDoc) {  EventOrganizerList.add(UserDoc.id);  });
    await Future.forEach(UsersInvitedUsersCollection.docs, (UserDoc) {  EventUsersInviteList.add(UserDoc.id);  });
    await Future.forEach(UsersWaitListCollection.docs, (UserDoc) {  EventUsersWaitList.add(UserDoc.id);  });

    await Future.forEach(EventUsersInviteList, (element) async{
      if(element==(_auth.currentUser==null ? "" : _auth.currentUser!.phoneNumber)){ setState(() {IAmInvited=true;});} // Проверка себя на наличие в инвайтлисте
    });

    await Future.forEach(EventUsersWaitList, (element) async{
      if(element==(_auth.currentUser==null ? "" : _auth.currentUser!.phoneNumber)){ setState(() {IAmInWaitList=true;});} // Проверка себя на наличие в вейтлисте
      var data=await firestore.collection("UsersCollection").doc(element).get(); var userdata=data.data();
      userdata!["role"]=-1; userdata!["doc_id"]=data.id;
      EventUsersListData.add(userdata);
    });

    await Future.forEach(EventOrganizerList, (element) async{
      if(element==(_auth.currentUser==null ? "" : _auth.currentUser!.phoneNumber)){ setState(() {IAmOrganizer=true;});} // Проверка организатора на наличие в мероприятии
      var data=await firestore.collection("UsersCollection").doc(element).get(); var userdata=data.data();
      userdata!["role"]=1; userdata!["doc_id"]=data.id;
      EventUsersListData.add(userdata);
      EventOrganizerListData.add(userdata);
    });

    await Future.forEach(EventUsersList, (element) async{
      if(element==(_auth.currentUser==null ? "" : _auth.currentUser!.phoneNumber)){ setState(() {IsUserIn=true;});} // Проверка юзера на наличие в мероприятии
      var data=await firestore.collection("UsersCollection").doc(element).get(); var userdata=data.data();
      userdata!["role"]=0; userdata!["doc_id"]=data.id;
      (EventUsersListData.any((user) => user['phone']==element))  ?  null : EventUsersListData.add(userdata);
    });

    await Future.forEach(EventUsersListManual, (element) async{
      var userdata=element;
      userdata!["role"]=-2;
      (EventUsersListData.any((user) => user['phone']==element))  ?  null : EventUsersListData.add(userdata);
    });


    EventUsersListData.sort((a,b){
      if(a['role']>b['role']) return -1;
      return 1;
    });

    setState(() {
      show_buttons=true;join_wait_bool=false;add_friend_wait_bool=false;
      if((widget.data as Map).containsKey("pay_with_my_wallet")) pay_with_my_wallet=widget.data["pay_with_my_wallet"];
    });
  }



  FirebaseWebSocket(Switch){

    final MessagesRef = firestore.collection("Events").doc(widget.data['doc_id']).collection("Messages");

    if(Switch) { print("Слушаем стрим ");
    stream = MessagesRef.snapshots().listen((event) { GetAllMessage();},
      onError: (error) {print("Listen failed: $error");},
    );
    } else { print("Не слушаем"); stream.cancel();}

  }

  FirebaseWebSocketEventData(Switch){

    final MessagesRef = firestore.collection("Events").doc(widget.data['doc_id']);

    if(Switch) { print("Слушаем стрим ивента");
    stream = MessagesRef.snapshots().listen((event) {
      print("Обновление данных");

      var AllValues=(widget.data as Map).keys.toList();
      AllValues.forEach((keyy) {
        if(keyy!="doc_id") widget.data[keyy]=event.data()![keyy];
      });
      GetEventUsersCollection();
      setState(() { });
    },
      onError: (error) {print("Listen failed: $error");},
    );
    } else { print("Не слушаем ивент"); stream.cancel();}

  }

  late VideoPlayerController video_controller;
  bool video_load=false;

  
  @override
  void initState() {
    print("_____________"+widget.data.toString());
    peoples_length=widget.data["peoples"];
    IsPromoCorrect();
    if((widget.data as Map).containsKey("my_video_link")) LoadVideo();

    // GetEventUsersCollection(); // Перенесено в FirebaseWebSocketEventData
    FirebaseWebSocket(true);
    FirebaseWebSocketEventData(true);

    peoples_length=widget.data['peoples'];

    // TODO: implement initState
    super.initState();
  }

  void LoadVideo() {
    setState(() { video_load=false; });

    if(widget.data['my_video_link']!="") {
      video_controller = VideoPlayerController.networkUrl(Uri.parse(widget.data['my_video_link']))
        ..initialize().then((_) {
          video_controller.play();
          video_controller.setVolume(0);
          video_controller.setLooping(true);
          setState(() { video_load=true; });
          // Ensure the first frame is shown after the video is initialized
        });
      setState(() {
        print("Видео загружено");
      });
    }

  }


  void PromoIsCorrect(name,value) async{
    await firestore.collection("Events").doc(widget.data['doc_id']).collection("PromoUsers").add({
      "phone":" ",
      "promo_name":name.toString(),
      }
    );
    setState(() {after_discount_price_percent=value;});
  }

  void IsPromoCorrect() async{
    var data = await firestore.collection("Events").doc(widget.data['doc_id']).collection("PromoUsers").get();
    data.docs.forEach((element) {

      if(element.data()['phone']==" "){
        if(element.data().containsKey("promo_name")){
          if(element.data()['promo_name']=widget.data['promo_code_name']) setState(() {after_discount_price_percent=(widget.data as Map)['promo_code_value'];});
          if(element.data()['promo_name']=widget.data['promo_code_name2']) setState(() {after_discount_price_percent=(widget.data as Map)['promo_code_value2'];});
          if(element.data()['promo_name']=widget.data['promo_code_name3']) setState(() {after_discount_price_percent=(widget.data as Map)['promo_code_value3'];});
          if(element.data()['promo_name']=widget.data['promo_code_name4']) setState(() {after_discount_price_percent=(widget.data as Map)['promo_code_value4'];});
          if(element.data()['promo_name']=widget.data['promo_code_name5']) setState(() {after_discount_price_percent=(widget.data as Map)['promo_code_value5'];});
        } else {
          setState(() {after_discount_price_percent=(widget.data as Map)['promo_code_value'];});
        }
      };
    });
  }
  
  void LeaveFromEvent() async{

    print("Удаление юзера (себя)");
    bool success=await DeleteMySelfDialog();
    if(success) {


      EventUsersListData.removeWhere((element) => element['phone']==_auth.currentUser!.phoneNumber);
      await firestore.collection("Events").doc(widget.data['doc_id']).collection("Users").doc(_auth.currentUser!.phoneNumber).delete();
      await firestore.collection("UsersCollection").doc(_auth.currentUser!.phoneNumber).collection("Events").doc(widget.data['doc_id']).delete();

      setState(() {
        IsUserIn=false;
        IAmInWaitList=false;
      });

      await firestore.collection("Events").doc(widget.data['doc_id']).update({"peoples":peoples_length-1,}); // Добавляем юзера в список
      UserMessage("You left the event", context);
    }

  }

  Future<bool> DeleteMySelfDialog() async{
    // bool reuslt=false;

    var result=await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(IAmInWaitList ? "Are you sure you want to get out from wait list?" : "Are you sure you want to get out from this event?"),
        actions: <Widget>[
          CupertinoDialogAction(
            child: Text("Cancel"),
            isDefaultAction: false,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            child: Text("Yes"),
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),

        ],
      ),
    );

    return result;
  }
  

  FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: EventAppBarPro(title: widget.data['short_address'],data: widget.data),
      backgroundColor: groupValue!=2 ? Colors.white : Color.fromRGBO(236, 236, 242, 1),
      body: Stack(
        children: [
          if(FinalGroupValue==0) ...[
            EventDetails(
              data: widget.data,
              join_button:() async{
                if(_auth.currentUser==null) setState(() {  show_sign_popup = true;  });
                else {
                  if(IAmInWaitList==false||IsUserIn) {
                    if(widget.data['price']=="0") JoinFree();
                    else PayForOrganizerWallet();
                  } else LeaveFromEvent();
                }
              },
              peoples: peoples_length,
              IsUserIn: IsUserIn,
              IAmInvited: IAmInvited,
              IAmOrganizer: IAmOrganizer,
              IInWaitList: IAmInWaitList,
              show_buttons: show_buttons,
              IAmAdmin: IAmAdmin,
              peoples_length: peoples_length,
              join_wait_bool: join_wait_bool,
              EventOrganizerListData:EventOrganizerListData,
              russian_language: russian_language,
              add_friend_wait_bool: add_friend_wait_bool,
              get_users: GetEventUsersCollection,
              after_discount_price_percent: after_discount_price_percent,
              PromoIsCorrect: PromoIsCorrect,
              video_controller: ((widget.data as Map).containsKey("my_video_link")) ? widget.data['my_video_link']!="" ? video_controller : null : null, load_video: LoadVideo, is_video_load: video_load, pay_with_my_wallet: pay_with_my_wallet,
            ),
          ] else if(FinalGroupValue==1) ...[
            ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 86,horizontal: (MediaQuery.of(context).size.width>800 ? MediaQuery.of(context).size.width/4 : 28)),
                itemCount: EventUsersListData.length, shrinkWrap: true,
                separatorBuilder: (context,index){return Divider(height: 16,color: Colors.white,);},
                itemBuilder: (contex,index){
                  return EventUserCard(context, EventUsersListData[index]['nickname'], EventUsersListData[index]['role']==0 ? "Online" : EventUsersListData[index]['role']==1 ? "Organizer" : EventUsersListData[index]['role']==(-2) ? "Member" : "Wait for accept", EventUsersListData[index]['avatar_link'], EventUsersListData[index]['doc_id'],IAmOrganizer,(){
                    // DeleteUserDialog(EventUsersListData[index]['doc_id'], EventUsersListData[index]['role']!=0,index,EventUsersListData[index]['role']==(-2));
                  },(){
                    // AddUserFromWaitList(EventUsersListData[index]['doc_id'],index);
                  },EventUsersListData[index].containsKey("safe_badge") ? EventUsersListData[index]["safe_badge"] : false);
                }
            ),
          ] else if(FinalGroupValue==2) ...[
            // ChatWidget(MessageController: MessageController,MessageNode: MessageNode, MessageList: MessageList,SendMessage: (value){SendMessage(value);}, IsEventChat: true,),
          ] else if(FinalGroupValue==3) ...[
            EventAddress(data: widget.data,russian_language: russian_language, is_user_in: IsUserIn, i_am_organizer: IAmOrganizer,)
          ],
          if(widget.data.containsKey("infinity_users")) ...[
            if(widget.data["infinity_users"]) ...[
              if(!widget.data['is_online']) Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          spreadRadius: 20,
                          blurRadius: 20
                      )
                    ]
                ),
                height: 70,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(height: 16,),
                    Container(
                      width: double.infinity,
                      child: CupertinoSlidingSegmentedControl<int>(
                        backgroundColor:  CupertinoColors.systemGrey5,
                        thumbColor: CupertinoColors.white,
                        padding: EdgeInsets.all(2),
                        groupValue: groupValue,
                        children:  {
                          0: buildSegment("Details"),
                          1: buildSegment("Chat"),
                          2: buildSegment("Address"),
                        },
                        onValueChanged: (value){

                          setState(() {
                            if(value==0) {
                                groupValue = 0;
                                FinalGroupValue = 0;
                              }
                              if(value==1) {
                                groupValue = 1;
                                FinalGroupValue = 2;
                              }
                              if(value==2) {
                                groupValue = 2;
                                FinalGroupValue = 3;
                              }
                            });
                        },
                      ),
                    ),
                  ],
                ),
              ) else Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          spreadRadius: 20,
                          blurRadius: 20
                      )
                    ]
                ),
                height: 70,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(height: 16,),
                    Container(
                      width: double.infinity,
                      child: CupertinoSlidingSegmentedControl<int>(
                        backgroundColor:  CupertinoColors.systemGrey5,
                        thumbColor: CupertinoColors.white,
                        padding: EdgeInsets.all(2),
                        groupValue: groupValue,
                        children:  {
                          0: buildSegment("Details"),
                          1: buildSegment("Chat"),
                        },
                        onValueChanged: (value){

                          setState(() {
                            if(value==1) {
                                groupValue = 1;
                                FinalGroupValue = 2;
                              } else {
                                FinalGroupValue = 0;
                                groupValue = 0;
                              }
                            });
                        },
                      ),
                    ),
                  ],
                ),
              )
            ] else GroupChoice(context)
          ] else ...[
            GroupChoice(context),
          ],
          if(show_sign_popup) ...[
            InkWell(
              onTap: (){
                setState(() {  show_sign_popup=false;  });
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black54,
              ),
            ),
            Align(
              child: Container(
                padding: EdgeInsets.all(24),
                height: 440,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width>800 ? MediaQuery.of(context).size.width/4 : 16,
                ),
                child: Column(
                  children: [
                    SizedBox(height: 36,),
                    Container(
                        width: 300,
                        height: 200,
                        child: Image.asset("lib/assets/welcome_img.png")),
                    SizedBox(height: 24,),
                    Center(
                        child: Text("You need to log in to your account to purchase tickets.",textAlign: TextAlign.center,style: TextStyle(fontSize: 20),)
                    ),
                    SizedBox(height: 24,),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: (){
                              final page = SignInPage();
                              Navigator.of(context).push(CustomPageRoute(page));
                            },
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                  color: Colors.black,borderRadius: BorderRadius.circular(12)
                              ),
                              child: Center(child: Text("Sign in",style: TextStyle(fontSize: 16,color: Colors.white,fontWeight: FontWeight.w600),textAlign: TextAlign.center,)),
                            ),
                          ),
                        ),
                        SizedBox(width: 16,),
                        Expanded(
                          child: InkWell(
                            onTap: (){
                              final page = SignUpPage();
                              Navigator.of(context).push(CustomPageRoute(page));
                            },
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                  color: Colors.black,borderRadius: BorderRadius.circular(12)
                              ),
                              child: Center(child: Text("Sign up",style: TextStyle(fontSize: 16,color: Colors.white,fontWeight: FontWeight.w600),textAlign: TextAlign.center,)),
                            ),
                          ),
                        ),

                      ],
                    ),

                  ],
                ),
              ),
            ),
          ],
          Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 64,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12,blurRadius: 20)]
                ),
                child: Container(
                    margin:  EdgeInsets.symmetric(horizontal: (MediaQuery.of(context).size.width>800 ? MediaQuery.of(context).size.width/4 : 28)) ,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 16,),
                            Text("Get the best",style: TextStyle(fontWeight: FontWeight.w700),),
                            Text("R-Unity experience",style: TextStyle(fontWeight: FontWeight.w700),),
                          ],
                        ),
                        InkWell(
                          onTap: () async{
                            var url = "https://apps.apple.com/ru/app/r-unity/id6474701497";
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            } else {
                              throw 'Could not launch $url';
                            }
                          },
                          child: Container(
                            height: 42,
                            width: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: Colors.white,
                              border: Border.all(width: 1,color: Colors.grey),
                              // boxShadow: [BoxShadow(color: Colors.black12,blurRadius: 10)]
                            ),
                            child: Center(
                              child: Text("Join in the app",style: TextStyle(color: PrimaryCol,fontWeight: FontWeight.w700),),
                            ),
                          ),
                        )
                      ],
                    )
                ),
              )
          )

        ],
      ),
    );
  }

  Container GroupChoice(BuildContext context) {
    return Container(
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      spreadRadius: 20,
                      blurRadius: 20
                  )
                ]
            ),
            height: 70,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SizedBox(height: 16,),
                Container(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<int>(
                    backgroundColor:  CupertinoColors.systemGrey5,
                    thumbColor: CupertinoColors.white,
                    padding: EdgeInsets.all(2),
                    groupValue: groupValue,
                    children: !widget.data['is_online'] ? {
                      0: buildSegment("Details"),
                      1: buildSegment("Users"),
                      2: buildSegment("Chat"),
                      3: buildSegment("Address"),
                    } : {
                      0: buildSegment("Details"),
                      1: buildSegment("Users"),
                      2: buildSegment("Chat"),
                    },
                    onValueChanged: (value){

                      setState(() {
                        if(widget.data.containsKey("infinity_users")&&value==2) {
                          if(value==2&&widget.data['infinity_users']) UserMessage("Chat is not available for this event", context);
                          else {
                            if(!IsUserIn&&value==2&&!IAmAdmin) UserMessage("Chat only for members", context);
                            else {
                              FinalGroupValue = value!;
                              groupValue = value;
                      }
                    }
                        } else {
                          if(!IsUserIn&&value==2&&!IAmAdmin) UserMessage("Chat only for members", context);
                          else {
                            FinalGroupValue = value!;
                              groupValue = value;
                          }
                  }


                      });
                    },
                  ),
                ),
              ],
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

  PreferredSizeWidget EventAppBarPro({required title,required data}) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,

      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon(CupertinoIcons.location_solid,size: 16,color: Colors.grey,),
          // SizedBox(width: 8,),
          Text(title.toString().length>14 ? title.toString().substring(0,14)+"..." : title,style: TextStyle(color: Colors.black54,fontWeight: FontWeight.w400,),),
          // SizedBox(width: 16,),
        ],
      ),
      centerTitle: true,
      actions: [
        if((data as Map).containsKey("telegram"))...[
          if((data as Map)["telegram"].length>0&&(data as Map)["social_media_exist"])
            InkWell(
              onTap: () async{
                var url = data['telegram'];
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  throw 'Could not launch $url';
                }
              },
              child: Opacity(opacity: 0.4,
                child: Container(
                    width: 24,
                    height: 24,
                    child: Image.asset("lib/assets/Icons/LightPng/telegram.png")),
              ),
            ),
          SizedBox(width: 8),
        ],

        if((data as Map)["instagram"].length>0&&(data as Map)["social_media_exist"])
          InkWell(
            onTap: () async{
              var url = data['instagram'];
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                throw 'Could not launch $url';
              }
            },
            child: Container(
              width: 24,
              height: 24,
              child: Opacity(opacity: 0.4,
                  child: Image.asset("lib/assets/Icons/LightPng/Instagram.png")),
            ),
          ),
        SizedBox(width: 8),
        if((data as Map)["facebook"].length>0&&(data as Map)["social_media_exist"])
          InkWell(
            onTap: () async{

              var url = data['facebook'];
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                throw 'Could not launch $url';
              }

            },
            child: Container(
              width: 24,
              height: 24,
              child: Opacity(opacity: 0.4,
                  child: Image.asset("lib/assets/Icons/LightPng/Facebook.png")
              ),
            ),
          ),
        SizedBox(width: 12,)
      ],
    );
  }



  void dispose() {

    ((widget.data as Map).containsKey("my_video_link") ? (widget.data['my_video_link']!="" ? video_controller.dispose() : null) : null);
    FirebaseWebSocket(false);
    FirebaseWebSocketEventData(false);
    super.dispose();
  }

  Widget buildSegment(String text){
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(text,style: TextStyle(fontSize: 14, color: Colors.black87,),),
    );
  }
}



class EventDetails extends StatefulWidget {
  final data;
  final IsUserIn;
  final IAmOrganizer;
  final IAmAdmin;
  final IInWaitList;
  final IAmInvited;
  final peoples;
  Function join_button;
  final show_buttons;
  final peoples_length;
  final join_wait_bool;
  final add_friend_wait_bool;
  final EventOrganizerListData;
  final russian_language;
  final get_users;
  final after_discount_price_percent;
  final video_controller;
  final load_video;
  final is_video_load;
  final pay_with_my_wallet;
  Function PromoIsCorrect;
  EventDetails({
    Key? key,
    required this.data,
    required this.IsUserIn,
    required this.peoples,
    required this.join_button,
    required this.IAmOrganizer,
    required this.IAmAdmin,
    required this.IAmInvited,
    required this.IInWaitList,
    required this.show_buttons,
    required this.peoples_length,
    required this.join_wait_bool,
    required this.add_friend_wait_bool,
    required this.EventOrganizerListData,
    required this.russian_language,
    required this.get_users,
    required this.after_discount_price_percent,
    required this.PromoIsCorrect,
    required this.video_controller,
    required this.load_video,
    required this.is_video_load,
    required this.pay_with_my_wallet,
  }) : super(key: key);

  @override
  State<EventDetails> createState() => _EventDetailsState();
}

class _EventDetailsState extends State<EventDetails> {

  Map EnglMonths={1:"January", 2:"February", 3:"March", 4:"April", 5:"May", 6:"June", 6:"Jule", 8:"August", 9:"September", 10:"October", 11:"November", 12:"December",};
  Map RusMonths={1:"января", 2:"феварля", 3:"марта", 4:"апреля", 5:"мая", 6:"июня", 6:"июля", 8:"августа", 9:"сентября", 10:"октября", 11:"ноября", 12:"декабря",};
  Map RusDays={"Monday":"Понедельник", "Tuesday":"Вторник", "Wednesday":"Среда", "Thursday":"Четверг", "Friday":"Пятница", "Saturday":"Суббота", "Sunday":"Воскресенье"};

  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool IsApproved=false;

  bool big=false;



  TextEditingController PromoController=TextEditingController();
  FocusNode PromoNode=FocusNode();




  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {


    if((widget.data as Map).containsKey("approved")){
      IsApproved=widget.data['approved'];
    }
    // TODO: implement initState
    super.initState();
  }

  bool sound_on=false;

  @override
  Widget build(BuildContext context) {
    var DateEpoch=DateTime.fromMillisecondsSinceEpoch(widget.data['date']);
    var DateName=DateFormat('EEEE').format(DateEpoch);
    var DateNameMonth=DateFormat('MMMM').format(DateEpoch);



    return Stack(
      children: [
        SingleChildScrollView(
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // widget.data.containsKey("infinity_users") ? (widget.data['infinity_users'] ? 16 : 86) : 86 SizedBox(height: 72,),
                if(widget.data.containsKey("infinity_users")) ...[
                  if(!widget.data['infinity_users']&&!widget.data['is_online']) SizedBox(height: 72,)
                  else if (widget.data['infinity_users']&&!widget.data['is_online']) SizedBox(height: 72,)
                  else if (widget.data['infinity_users']&&widget.data['is_online']) SizedBox(height: 72,)
                  else SizedBox(height: 72,),
                ] else ...[
                  SizedBox(height: 72,),
                ],
                if((widget.data as Map)['additional_photo_links'].length!=0||((widget.data as Map).containsKey("my_video_link") ? widget.data['my_video_link']!="" : false))...[
                  InkWell(
                    onTap: (){
                      // OrderHasBeenPlaced();
                      setState(() {
                        big=!big;
                      });
                    },
                    child: AnimatedSize(
                      curve: Curves.fastLinearToSlowEaseIn,
                      alignment: Alignment.topCenter,
                      duration: Duration(milliseconds: 500),
                      child: CarouselSlider(
                        options: CarouselOptions(height:big ? 600 : 300.0),
                        items: ((
                            ((widget.data as Map).containsKey("my_video_link") ? widget.data['my_video_link']!="" : false) ?
                            (((widget.data as Map)['additional_photo_links'].length==0 ?
                            [widget.data['my_video_link'],widget.data['photo_link'],] :
                            [widget.data['my_video_link'],...widget.data['additional_photo_links']]))

                                :

                            widget.data['additional_photo_links']
                        ) as List<dynamic>).map((i) {
                          var ContainerWidth=(MediaQuery.of(context).size.width-(16*6));

                          return Builder(
                            builder: (BuildContext context) {
                              return Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: EdgeInsets.symmetric(horizontal: 5.0),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.black12
                                  ),
                                  child: ((widget.data as Map).containsKey("my_video_link") ? widget.data["my_video_link"]==i : false) ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      constraints: BoxConstraints(maxHeight: 300),
                                      height: 300,
                                      child: Stack(
                                        children: [
                                          Container(
                                              // padding: EdgeInsets.symmetric(
                                              //     vertical: !big ?
                                              //     (300-ContainerWidth*widget.data['video_size_index'])/2
                                              //         :
                                              //     widget.data['is_video_horizontal'] ?
                                              //     ( ( 600-ContainerWidth*widget.data['video_size_index'] ) / 2 )
                                              //         :
                                              //     (600-ContainerWidth/widget.data['video_size_index'])/2 ,
                                              //
                                              //     horizontal: big ?
                                              //       0
                                              //         :
                                              //     (widget.data['is_video_horizontal'] ?
                                              //       0
                                              //         :
                                              //     ((ContainerWidth-300*widget.data['video_size_index'])/2)) ),

                                              color: Colors.black,
                                              child: VideoPlayer(widget.video_controller)
                                          ),
                                          if(widget.is_video_load) SoundButton(),
                                        ],
                                      ),
                                    ),
                                  ) : Container(
                                    decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                            image: NetworkImage(i),
                                            fit: BoxFit.fitWidth
                                        )
                                    ),
                                  )
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ] else ...[
                  InkWell(
                    onTap: (){
                      setState(() {
                        big=!big;
                      });
                    },
                    child: AnimatedSize(
                      curve: Curves.fastLinearToSlowEaseIn,
                      alignment: Alignment.topCenter,
                      duration: Duration(milliseconds: 500),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        height:big ? 600 : 300.0,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.black,
                            image: DecorationImage(
                                image: NetworkImage(widget.data['photo_link']),fit: BoxFit.fitWidth
                            )
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 24,),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: (MediaQuery.of(context).size.width>800 ? MediaQuery.of(context).size.width/4 : 28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListView.separated(
                          padding: EdgeInsets.all(0), itemCount: widget.EventOrganizerListData.length, shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
                          separatorBuilder: (context,index){return Divider(height: 16,color: Colors.white,);},
                          itemBuilder: (contex,index){
                            return EventUserCard(context, widget.EventOrganizerListData[index]['nickname'], widget.EventOrganizerListData[index]['role']==0 ? "Online" : widget.EventOrganizerListData[index]['role']==1 ? "Organizer" : "Wait for accept", widget.EventOrganizerListData[index]['avatar_link'], widget.EventOrganizerListData[index]['doc_id'],false,(){

                            },(){

                            },(widget.EventOrganizerListData[index] as Map).containsKey("safe_badge") ? widget.EventOrganizerListData[index]["safe_badge"] : false);
                          }
                      ),
                      Divider(height: 32,color: Colors.black26,),
                      Text((widget.russian_language ? RusDays[DateName.toString()] : DateName.toString())+" "+DateEpoch.day.toString()+" "+( widget.russian_language ? RusMonths[DateEpoch.month] : EnglMonths[DateEpoch.month]),style: TextStyle(fontSize: 14,fontWeight: FontWeight.w700,color: Colors.black87,height: 1.4),),
                      Text(widget.russian_language&&widget.data['rus_header']!="" ? widget.data['rus_header'].toString().trim() : widget.data['header'].toString().trim(),style: TextStyle(fontSize: 24,fontWeight: FontWeight.w700,height: 1.4),),

                      if((widget.data as Map).containsKey("primary_language")) ...[
                        SizedBox(height: 2,),
                        if (widget.data['primary_language']=="All languages"||widget.data['primary_language']=="Все языки") Text("Primary language: all",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500,color: Colors.black54,height: 1.4),),
                        // if (widget.data['primary_language']=="Все языки") Text(AppLocalizations.of(context)!.primary_lang+" все",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500,color: Colors.black54,height: 1.4),),
                        if (widget.data['primary_language']=="English") Text("Primary language: "+" English",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500,color: Colors.black54,height: 1.4),),
                        if (widget.data['primary_language']=="American English") Text("Primary language: "+" American English",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500,color: Colors.black54,height: 1.4),),
                        if (widget.data['primary_language']=="Русский") Text("Primary language: "+" Русский",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500,color: Colors.black54,height: 1.4),),
                        if (widget.data['primary_language']=="Українська") Text("Primary language: "+" Українська",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500,color: Colors.black54,height: 1.4),),
                        if (widget.data['primary_language']=="Қазақ") Text("Primary language: "+" Қазақ",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500,color: Colors.black54,height: 1.4),),
                        if (widget.data['primary_language']=="հայերեն") Text("Primary language: "+" հայերեն",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500,color: Colors.black54,height: 1.4),),
                      ],
                      Divider(height: 32,color: Colors.black26,),
                      Wrap(
                        runSpacing: 12,
                        spacing: 12,
                        children: [
                          IconText(DateTime.fromMillisecondsSinceEpoch(widget.data['date']).hour.toString()+":"+(DateTime.fromMillisecondsSinceEpoch(widget.data['date']).minute>9 ? DateTime.fromMillisecondsSinceEpoch(widget.data['date']).minute.toString() : "0"+DateTime.fromMillisecondsSinceEpoch(widget.data['date']).minute.toString() )+
                              " | "+widget.data['duration'].toString()+" min.","TimeSquare.png"),

                          widget.data['price']=="0" ? IconText("Free".toString(),"Wallet.png") :
                          IconText("\$"+(int.parse(widget.data['price'])*(widget.after_discount_price_percent/100)).toString(),"Wallet.png"),

                          if(widget.data.containsKey("infinity_users")) ...[
                            if(!widget.data['infinity_users']) ...[
                              widget.data['unlimited_users'] ? IconText(widget.data['max_peoples'].toString(),"Users.png") : IconText(widget.peoples_length.toString()+"/"+widget.data['max_peoples'].toString(),"Users.png"),
                              if((widget.data as Map).containsKey("kids_allowed")) ...[if(widget.data['kids_allowed']) IconText("You can come with children","gameboy.png")],
                            ]
                          ] else ...[
                            widget.data['unlimited_users'] ? IconText(widget.data['max_peoples'].toString(),"Users.png") : IconText(widget.peoples_length.toString()+"/"+widget.data['max_peoples'].toString(),"Users.png"),
                            if((widget.data as Map).containsKey("kids_allowed")) ...[if(widget.data['kids_allowed']) IconText("You can come with children","gameboy.png")],
                          ]

                        ],
                      ),

                      Divider(height: 32,color: Colors.black26,),




                      if(widget.after_discount_price_percent!=100) ...[
                        SizedBox(height: 12,),
                        InkWell(
                          onTap: () async{

                          },
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: CupertinoColors.systemGrey5
                            ),
                            child: Center(
                              child: Text("Promocode",style: TextStyle(fontSize: 16,color: Colors.black54,fontWeight: FontWeight.w500),),
                              // child: Text(!IsApproved ? "Approve" : "Successfully approved",style: TextStyle(fontSize: 16,color: Colors.white),),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 12,),
                      // Text(AppLocalizations.of(context)!.about,style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
                      if((widget.pay_with_my_wallet||widget.data['price']=="0") && widget.show_buttons) InkWell(
                        onTap: (){  widget.join_button();  },
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(widget.IsUserIn ? "Leave" : (widget.IInWaitList ? "Leave from wait list" : "Join"),style: TextStyle(color: Colors.white),),
                          ),
                        ),
                      ),
                      SizedBox(height: 24,),
                      Text("About",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
                      SizedBox(height: 8,),
                      Text(widget.russian_language&&widget.data['rus_about']!='' ? widget.data['rus_about'] : widget.data['about'], style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500,color: Colors.black54,height: 1.5),),
                      if(widget.data['additional_text_count']>0)...[
                        SizedBox(height: 24,),
                        Text(widget.russian_language&&widget.data['rus_header1']!='' ? widget.data['rus_header1'] : widget.data['header1'], style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
                        SizedBox(height: 8,),
                        Text(widget.russian_language&&widget.data['rus_about1']!='' ? widget.data['rus_about1'] : widget.data['about1'], style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500,color: Colors.black54,height: 1.5),),
                      ],
                      if(widget.data['additional_text_count']>1)...[
                        SizedBox(height: 24,),
                        Text(widget.russian_language&&widget.data['rus_header2']!='' ? widget.data['rus_header2'] : widget.data['header2'], style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
                        SizedBox(height: 8,),
                        Text(widget.russian_language&&widget.data['rus_about2']!='' ? widget.data['rus_about2'] : widget.data['about2'], style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500,color: Colors.black54,height: 1.5),),
                      ],
                      SizedBox(height: 24,),
                      InkWell(
                        onTap: (){
                          // UserMessage("Thank you for your application, we will consider it and take restrictive measures", context);
                        },
                          child: Text("Tap to report a violation of the rules",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600,color: Colors.red),)
                      ),
                      SizedBox(height: 24,),
                      InkWell(
                          onTap: () async{
                            await Clipboard.setData(ClipboardData(text: "https://r-unity.web.app/#/"+widget.data['doc_id'].toString()));
                            UserMessage("Link copied",context);
                          },
                          child: Text("Copy event link",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600,color: Colors.red),)
                      ),
                      SizedBox(height: 24,),
                    ],
                  ),
                ),
                SizedBox(height: 72,),
              ],
            ),
          ),
        ),
        // Positioned(
        //   bottom: 24,
        //   right: 24,
        //   child: Container(
        //     height: 120,
        //     width: 200,
        //     decoration: BoxDecoration(
        //       color: CupertinoColors.systemGrey5,
        //       borderRadius: BorderRadius.circular(12)
        //     ),
        //     child: ClipRRect(
        //       borderRadius: BorderRadius.circular(12),
        //       child: VideoPlayer(video_controller),
        //     ),
        //   ),
        // )
      ],
    );
  }



  Positioned SoundButton() {
    return Positioned(
        top: 12,
        right: 12,
        child: GestureDetector(
          onTap: (){
            setState(() {
              print("sound_on "+sound_on.toString());
              if(sound_on) (widget.video_controller as VideoPlayerController).setVolume(0);
              else (widget.video_controller as VideoPlayerController).setVolume(1);
              setState(() {
                sound_on=!sound_on;
              });
            });
          },
          child: Container(
            height: 32,
              width: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white
              ),
              child: sound_on ? Icon(Icons.music_note,color: Colors.black,) : Icon(Icons.music_off,color: Colors.black,)
          ),
        )
    );
  }

  @override
  void dispose() {

    // TODO: implement dispose
    super.dispose();
  }








}

class EventAddress extends StatefulWidget {
  final data;
  final russian_language;
  final is_user_in;
  final i_am_organizer;
  const EventAddress({Key? key,required this.data,required this.russian_language,required this.is_user_in,required this.i_am_organizer}) : super(key: key);

  @override
  State<EventAddress> createState() => _EventAddressState();
}

class _EventAddressState extends State<EventAddress> {
  bool AllowMySelfGeo=true; final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  bool AllowMap=false; final Set<Marker> _markers = new Set(); final Set<Marker> empty_markers = new Set(); final Set<Circle> circles = new Set(); final Set<Circle> circles_empty = new Set();

  CameraPosition _kGooglePlex = CameraPosition(target: LatLng(34.052235,-118.243683),   zoom: 14.4746,);
  bool HoldScreen=false;



  @override
  void initState() {


    InitMapSettings();

    // TODO: implement initState
    super.initState();
  }

  void InitMapSettings() {
    var widget_data=widget.data as Map;
    if(!widget_data['is_online']){
      var _GeoPoint=(widget.data as Map)['geo_point'] as GeoPoint;

      AllowMap=true;
      _kGooglePlex=CameraPosition(target: LatLng(_GeoPoint.latitude,_GeoPoint.longitude),   zoom: 14.4746,);
      _markers.clear();
      circles.clear();

      _markers.add(Marker(
        markerId: MarkerId("place.id"),
        position: LatLng(_GeoPoint.latitude,_GeoPoint.longitude),
        infoWindow: InfoWindow(
          title: widget.data['header'],
        ),
        icon: BitmapDescriptor.defaultMarker,
      ));

      if((widget.data as Map)['aproximate_geo_point']!=""){
        var _GeoPointCircle=(widget.data as Map)['aproximate_geo_point'] as GeoPoint;
        if(!widget.is_user_in&&(widget.data as Map)["hide_exact_address"]&&!widget.i_am_organizer){
          print("Change");
          _kGooglePlex=CameraPosition(target: LatLng(_GeoPointCircle.latitude,_GeoPointCircle.longitude),   zoom: 14.4746,);
        }
        circles.add(
          Circle(
              circleId: CircleId("id"),
              center: LatLng(_GeoPointCircle.latitude,_GeoPointCircle.longitude),
              radius: 300,
              fillColor: Colors.black12,
              strokeWidth: 2,
              strokeColor: Colors.blueAccent
          ),
        );
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        physics: HoldScreen ? NeverScrollableScrollPhysics() : ScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 96,),
            // if(AllowMap) ...[
            //   Container(
            //     height: 300,
            //     width: MediaQuery.of(context).size.width-32,
            //     child: ClipRRect(
            //       borderRadius: BorderRadius.circular(16),
            //       child: GoogleMap(
            //         zoomControlsEnabled: false,
            //         // zoomGesturesEnabled: false,
            //         mapType: GM.MapType.normal,
            //         myLocationButtonEnabled: true,
            //         myLocationEnabled: AllowMySelfGeo,
            //         initialCameraPosition: _kGooglePlex,
            //         gestureRecognizers: Set()..add(Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer())),
            //         onMapCreated: (GoogleMapController controller) {
            //           _controller.complete(controller);
            //         },
            //         circles: widget.is_user_in ? circles_empty : ((widget.data as Map)["hide_exact_address"]) ? circles : circles_empty,
            //         markers: !widget.is_user_in ? (widget.i_am_organizer||!(widget.data as Map)["hide_exact_address"] ? _markers : empty_markers) : _markers,
            //
            //       ),
            //     ),
            //   ),
            //   SizedBox(height: 24),
            //   // if(widget.is_user_in) ButtonPro(AppLocalizations.of(context)!.show_on_map, (){ OpenMap(); }, false),
            //   // if(widget.is_user_in) ButtonPro(AppLocalizations.of(context)!.show_on_map, (){ OpenMap(); }, false),
            // ],
            SizedBox(height: 24,),
            // if(widget.is_user_in) Text(AppLocalizations.of(context)!.address,style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
            if(widget.is_user_in) Text("Addres",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
            SizedBox(height: 8,),
            if(widget.is_user_in) Text(widget.russian_language&&widget.data['rus_address']!="" ? widget.data['rus_address'] : widget.data['address'],style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500,color: Colors.black54,height: 1.4),),
            SizedBox(height: 16,),
            if(widget.data['location_info'].length!=0&&widget.is_user_in) ...[
              // Text(AppLocalizations.of(context)!.location_info,style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
              Text("Location info",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
              SizedBox(height: 8,),
              Text(widget.russian_language&&widget.data['rus_location_info']!="" ? widget.data['rus_location_info'] : widget.data['location_info'],style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500,color: Colors.black54,height: 1.4),),
              SizedBox(height: 16,),
            ],
            if(widget.data['parking_info'].length!=0&&widget.is_user_in)...[
              // Text(AppLocalizations.of(context)!.parking_info,style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
              Text("Parking info",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
              SizedBox(height: 8,),
              Text(widget.russian_language&&widget.data['rus_parking_info']!=""? widget.data['rus_parking_info'] : widget.data['parking_info'],style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500,color: Colors.black54,height: 1.4),),
            ],
            SizedBox(height: 36,),

          ],
        ),
      ),
    );
  }
}


Widget EventUserCard(Context,Name,Status,Img,DocId,IAmOrganizer,DeleteButton,AddFromUsersList,IsVerified) {


  return GestureDetector(
    onTap: (){
      if(DocId!=" "){
        // final page = OtherUserPage(user_doc: DocId,);
        // Navigator.of(Context).push(CustomPageRoute(page));
      } else {
        // final page = UserPage();
        // Navigator.of(Context).push(CustomPageRoute(page));
      }
    },
    child: Container(
      height: 64,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                height: 68,
                width: 68,
                child: Stack(
                  children: [
                    if(Status=="Organizer") ...[
                      Container(
                        height: 68,
                        width: 68,
                        child: Image.asset("lib/assets/StoryBorder.png"),
                      ),
                    ],
                    Center(
                      child: Container(
                        height: 70,
                        width: 70,
                        child: Stack(
                          children: [
                            Center(
                              child: Container(
                                height: Status!="Organizer" ? 60 : 56,
                                width: Status!="Organizer" ? 60 : 56,
                                decoration: BoxDecoration(
                                    color: CupertinoColors.systemGrey3,
                                    borderRadius: BorderRadius.circular(Status!="Organizer" ? 16 : 16,),
                                    image: Img!="https://mygardenia.ru/uploads/pers1.jpg" ? DecorationImage(
                                        image: NetworkImage(Img),
                                        fit: BoxFit.cover
                                    ) : DecorationImage(
                                        image: AssetImage("lib/assets/avatar.png"),
                                        fit: BoxFit.cover
                                    )
                                ),
                              ),
                            ),
                            if(Status=="Organizer"&&IsVerified) Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [BoxShadow(color: Colors.black26,blurRadius: 20)]
                                    ),
                                    child: Center(child: Icon(CupertinoIcons.shield_lefthalf_fill,color: Colors.orange,size: 16,))
                                )
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12,),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8,),
                  Text(Name,style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),),
                  SizedBox(height: 4,),
                  if(Status=="Organizer") ...[
                    Text(IsVerified ? "Verified organizer" :"Organizer",style: TextStyle(fontWeight: FontWeight.w700,color: Colors.orange),),
                  ] else if (Status=="Member") ...[
                    Text("Added by organizer"),
                  ] else  ...[
                    Text(Status),
                  ]

                ],
              ),
            ],
          ),

        ],
      ),
    ),
  );
}



void ScaffoldMessaLong(message,context){
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    duration: Duration(seconds: 6),
    backgroundColor: PrimaryCol,
  ));
}