import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:event_web/event_page.dart';
import 'package:event_web/sign_in.dart';
import 'package:event_web/sign_up.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../custom_route.dart';

Color PrimaryCol=Color.fromRGBO(93, 42, 233, 1);

class MyEventList extends StatefulWidget {
  final doc_id;
  const MyEventList({Key? key,required this.doc_id}) : super(key: key);

  @override
  State<MyEventList> createState() => _MyEventListState();
}

class _MyEventListState extends State<MyEventList> {

  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String CurrentCategory="All categories";
  Map TranslatedCategory=Map();

  bool no_events=false;
  bool filters=false;
  bool ShowCallendar=false;
  bool free_events=false;
  bool category_exist=false;
  bool only_once=false;
  bool AllCategoryBool=true;
  bool show_sign_popup=false;


  int CalendarIndex=0;

  String first_name="";
  String last_name="";
  String avatar_link="";

  List EventsList = [];
  List MyEvents = [];
  List Categories = [];
  List OrganizerEvents = [];

  List<DateTime?> dates=[DateTime.now()];
  List<DateTime?> dates_two=[];
  List<DateTime?> dates_three=[];

  void GetUserData() async{
    var data=await firestore.collection("UsersCollection").doc(_auth.currentUser?.phoneNumber.toString()).snapshots().first;
    print("GetUserData "+data.get("firstname"));

    setState(() {
      first_name=data.get("firstname");
      last_name=data.get("lastname");
      avatar_link=data.get("avatar_link");
    });
  }

  Future<bool> GetData() async {
    print("GetData");


    EventsList = [];
    EventsList.clear();
    MyEvents = [];
    MyEvents.clear();
    OrganizerEvents = [];
    OrganizerEvents.clear();
    bool AllCategoryBool=CurrentCategory=="All categories";
    print("CurrentCategory "+CurrentCategory.toString());




    var EventCollection = await firestore.collection("Events").get();
    var EventDocs = EventCollection.docs;

    await Future.forEach(EventDocs, (doc) {
      var NewDocData=doc.data() as Map; NewDocData['doc_id']=doc.id;



        if(((NewDocData as Map).containsKey("approved") ? NewDocData["approved"] : false)&&IsDateCurrent(doc.data()['date'])){
          bool OneCategoryBool=CurrentCategory==doc.data()['category']||CurrentCategory==TranslatedCategory[doc.data()['category']];

          if(dates.length!=0&&dates_two.length!=0){

            if((dates.first as DateTime).day==(dates_two.first as DateTime).day&&(dates.first as DateTime).month==(dates_two.first as DateTime).month&&(dates.first as DateTime).year==(dates_two.first as DateTime).year){
              print("Сработало");
              if(free_events) ((AllCategoryBool||OneCategoryBool)&& !IsDateCurrentByDate(dates_two.first,doc.data()['date'],false) && doc.data()['price']=="0"&&IsDateCurrent(doc.data()['date'])) ? EventsList.add(NewDocData) : null;
              else ((AllCategoryBool||OneCategoryBool) && !IsDateCurrentByDate(dates_two.first,doc.data()['date'],false)  && IsDateCurrent(doc.data()['date'])) ? EventsList.add(NewDocData) : null;
            } else {
              if(free_events) ((AllCategoryBool||OneCategoryBool)&& !IsDateCurrentByDate(dates_two.first,doc.data()['date'],false) && IsDateCurrentByDate(dates.first,doc.data()['date'],true) && doc.data()['price']=="0"&&IsDateCurrent(doc.data()['date'])) ? EventsList.add(NewDocData) : null;
              else ((AllCategoryBool||CurrentCategory==OneCategoryBool) && !IsDateCurrentByDate(dates_two.first,doc.data()['date'],false) && IsDateCurrentByDate(dates.first,doc.data()['date'],true) && IsDateCurrent(doc.data()['date'])) ? EventsList.add(NewDocData) : null;
            }

          }
          if(dates.length!=0&&dates_two.length==0){
            if(free_events) {((AllCategoryBool||CurrentCategory==OneCategoryBool) && IsDateCurrentByDate(dates.first,doc.data()['date'],true) && doc.data()['price']=="0"&&IsDateCurrent(doc.data()['date'])) ? EventsList.add(NewDocData) : null;}
            else {((AllCategoryBool||CurrentCategory==OneCategoryBool) && IsDateCurrentByDate(dates.first,doc.data()['date'],true) && IsDateCurrent(doc.data()['date'])) ? EventsList.add(NewDocData) : null;};
          }
          if(dates.length==0&&dates_two.length!=0){
            if(free_events) ((AllCategoryBool||CurrentCategory==OneCategoryBool) && !IsDateCurrentByDate(dates_two.first,doc.data()['date'],false) && doc.data()['price']=="0"&&IsDateCurrent(doc.data()['date'])) ? EventsList.add(NewDocData) : null;
            else ((AllCategoryBool||CurrentCategory==OneCategoryBool) && !IsDateCurrentByDate(dates_two.first,doc.data()['date'],false) && IsDateCurrent(doc.data()['date'])) ? EventsList.add(NewDocData) : null;
          }
          if(dates.length==0&&dates_two.length==0){
            if(free_events) ((AllCategoryBool||CurrentCategory==OneCategoryBool) && doc.data()['price']=="0"&&IsDateCurrent(doc.data()['date'])) ? EventsList.add(NewDocData) : null;
            else ((AllCategoryBool||CurrentCategory==OneCategoryBool) && IsDateCurrent(doc.data()['date'])) ? EventsList.add(NewDocData) : null;
          }
        }

    });


    EventsList.sort((a,b){
      return (DateTime.fromMillisecondsSinceEpoch(a['date']) as DateTime).compareTo((DateTime.fromMillisecondsSinceEpoch(b['date']) as DateTime));
    });

    print("TEST 1 "+widget.doc_id.toString());
    if(EventsList.where((element) => element['doc_id']==widget.doc_id).length==1){
      print("TEST 2 "+widget.doc_id.toString());
      print("TEST 3 "+EventsList.where((element) => element['doc_id']==widget.doc_id).toString());
      final page = EventPage(data: EventsList.where((element) => element['doc_id']==widget.doc_id).first,);
      Navigator.of(context).push(CustomPageRoute(page));
    }


    setState(() {no_events=EventsList.length==0;});
    return true;
  }

  bool IsDateCurrent(Date){
    return DateTime.now().compareTo(DateTime.fromMillisecondsSinceEpoch(Date))==-1;
  }

  bool IsDateCurrentByDate(Date1,Date2,is_first_date){
    var date1=Date1 as DateTime;
    var date2=DateTime.fromMillisecondsSinceEpoch(Date2);
    if(date1.day==date2.day&&date1.month==date2.month&&is_first_date) {return true;}
    if(date1.day==date2.day&&date1.month==date2.month&&!is_first_date) {return false;}

    return Date1.compareTo(DateTime.fromMillisecondsSinceEpoch(Date2))==-1;
  }



  void GetCategories() async{
    Categories=[];
    Categories.add("All categories");
    var CategoriesCollection = await firestore.collection("Categories").get();
    category_exist=CategoriesCollection.docs.length!=0;

    await Future.forEach(CategoriesCollection.docs, (doc) {
      TranslatedCategory[doc.data()["name"]]=doc.data()["name_rus"];
      Categories.add(doc.data()['name_rus']);
    });



    setState(() { });
  }

  @override
  void initState() {
    print("InitState "+Uri.base.toString());
    GetCategories();
    if(_auth.currentUser!=null) GetUserData();
    // GetData();
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration(seconds: 1)).then((value) => GetData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Container(
                  margin:  EdgeInsets.symmetric(horizontal: (MediaQuery.of(context).size.width>800 ? MediaQuery.of(context).size.width/4 : 28)) ,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                  child: Text("R-Unity",style: TextStyle(fontWeight: FontWeight.w700,color: PrimaryCol,fontSize: 20),),
                                margin: EdgeInsets.only(top: 12),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if(_auth.currentUser!=null) ...[
                                      ProfileAvatar(_auth.currentUser!.phoneNumber),
                                      SizedBox(width: 8,),
                                      Text(first_name+" "+last_name,style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700)),
                                      SizedBox(width: 8,),
                                      InkWell(
                                          onTap: () {  SignOut(context: context);  },
                                          child: Icon(Icons.login,size: 20,)
                                      )
                                    ] else ...[
                                      InkWell(
                                        child: Text("Sign in",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700)),
                                        onTap: (){
                                          setState(() {  show_sign_popup=true;  });
                                        },
                                      ),
                                    ]

                                  ],
                                ),
                              )
                            ],
                          )
                      ),
                      SizedBox(height: _auth.currentUser!=null ? 56 : 24,),
                      if(EventsList.length!=0) FiltersWidget(context),
                      SizedBox(height: 36,),
                      if(EventsList.length==0) Center(child: CupertinoActivityIndicator()),
                      if(EventsList.length!=0) ListView.separated(
                          itemCount: EventsList.length,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          separatorBuilder: (context,index){
                            return SizedBox(height: 24,);
                          },
                          itemBuilder: (context,index){
                            return InkWell(
                                onTap: (){
                                    final page = EventPage(data: EventsList[index],);
                                    Navigator.of(context).push(CustomPageRoute(page));
                                },
                                child: EventCardForDeveloper(context: context,data: EventsList[index], russian_language: false,)
                            );
                          }
                      ),
                      SizedBox(height: 92,)
                    ],
                  ),
                ),
              ),
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
                    height: 450,
                    width: MediaQuery.of(context).size.width>800 ? 400 : double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    margin: EdgeInsets.symmetric( horizontal: 12 ),
                    child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 36,),
                          Center(
                            child: Container(
                                height: 200,
                                child: Image.asset("lib/assets/welcome_img.png")),
                          ),
                          SizedBox(height: 24,),
                          Center(child: Text("Welcome to R-Unity",style: TextStyle(fontSize: 24,fontWeight: FontWeight.w600),)),
                          SizedBox(height: 16,),
                          Center(
                            child: InkWell(
                              onTap: (){
                                final page = SignInPage();
                                Navigator.of(context).push(CustomPageRoute(page));
                              },
                              child: Container(
                                height: 56,
                                width: 300,
                                decoration: BoxDecoration(
                                    color: Colors.black,borderRadius: BorderRadius.circular(12)
                                ),
                                child: Center(child: Text("Sign in",style: TextStyle(fontSize: 16,color: Colors.white,fontWeight: FontWeight.w600),textAlign: TextAlign.center,)),
                              ),
                            ),
                          ),
                          SizedBox(height: 16,),
                          Center(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Dont’t have an account?"),
                                SizedBox(width: 8,),
                                InkWell(
                                    onTap: (){ final page = SignUpPage(); Navigator.of(context).push(CustomPageRoute(page));},
                                  child: Text("Sign up",style: TextStyle(fontWeight: FontWeight.w600,color: PrimaryCol),)
                                ),
                              ],
                            ),
                          ),

                        ],
                      ),
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
        ),
      ),
    );
  }

  Widget CategoriesDropDown(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 0,vertical: 0),
      decoration: BoxDecoration(
          border: Border.all(width: 1,color: Colors.black26),
          borderRadius: BorderRadius.circular(8)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          hint: Text(
            'Choice category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).hintColor,
            ),
          ),
          items: Categories.map((item) => DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          )).toList(),
          value: CurrentCategory,
          onChanged: (value) {
            setState(() {
              CurrentCategory = value!;
            });
            GetData();
          },
          dropdownStyleData: DropdownStyleData(
              maxHeight: 300,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12)
              )
          ),
          buttonStyleData: const ButtonStyleData(
            padding: EdgeInsets.symmetric(horizontal: 16),
            height: 48,
            width: 140,

          ),
          menuItemStyleData: const MenuItemStyleData(
            height: 40,
          ),
        ),
      ),
    );
  }


  Row PriceFilterToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Text(AppLocalizations.of(context)!.free,style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),),
        Text("Free",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),),
        CupertinoSwitch(
            value: free_events,
            activeColor: PrimaryCol,
            onChanged: (value) async{
              setState(() {
                free_events=!free_events;
              });
              GetData();

            }
        ),
      ],
    );
  }

  void SignOut({required context}) async{
    FirebaseAuth _auth = FirebaseAuth.instance;

    var result=await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        // title: Text(AppLocalizations.of(context)!.log),
        title: Text("Log out"),
        content: Text("Are you sure you want to log out?"),
        actions: <Widget>[
          CupertinoDialogAction(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            child: Text("OK"),
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if(result) {
      await _auth.signOut();
      setState(() {

      });
    }
  }

  InkWell FiltersWidget(BuildContext context) {
    return InkWell(
      onTap: (){
        setState(() {
          filters=!filters;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8,horizontal: 16),
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black12,blurRadius: 10)
            ]
        ),
        child: Column(
          children: [
            Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Text(AppLocalizations.of(context)!.event_filters,style: TextStyle(fontSize: 14,fontWeight: FontWeight.w600,color: Colors.black54),),
                        Text("Event filters",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w600,color: Colors.black54),),
                        !filters ? Icon(Icons.expand_more,color: Colors.black54) : Icon(Icons.expand_less,color: Colors.black54)
                      ],
                    ),
                    InkWell(
                      onTap: (){
                        setState(() {
                          CurrentCategory="All categories";
                          dates.clear();
                          dates_two.clear();
                          free_events=false;
                        });
                        GetData();
                      },
                      child: Container(
                          height: 24,
                          width: 68,

                          child: Align(
                              alignment: Alignment.centerRight,
                              // child: Text(AppLocalizations.of(context)!.clear,style: TextStyle(fontSize: 14,fontWeight: FontWeight.w600,color: Colors.black54),)
                            child: Text("Clear",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w600,color: Colors.black54),)
                          )
                      ),
                    ),
                  ],
                )
            ),
            if(filters) ...[
              if(category_exist) ...[
                SizedBox(height: 16,),
                CategoriesDropDown(context),
              ],
              Divider(height: 16,color: Colors.white,),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14,horizontal: 12),
                        height: 48,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                            border: Border.all(width: 1,color: Color.fromRGBO(177, 177, 177, 1))
                        ),
                        child: Text(
                          "from "+" "+
                          // AppLocalizations.of(context)!.from+" "+
                          //     AppLocalizations.of(context)!.from+
                              (dates.length!=0 ?
                              (((dates.first as DateTime).day<10 ? "0"+(dates.first as DateTime).day.toString() : (dates.first as DateTime).day.toString())+"."+
                                  ((dates.first as DateTime).month<10 ? "0"+(dates.first as DateTime).month.toString() : (dates.first as DateTime).month.toString())+"."+
                                  (dates.first as DateTime).year.toString()) : ""),
                          style: TextStyle(fontFamily: "SFPro",fontWeight: FontWeight.w500,color: Color.fromRGBO(98, 98, 98, 1)),
                        ),
                      ),
                      onTap: (){
                        setState((){
                          CalendarIndex=0;
                          ShowCallendar=true;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 16,),
                  Expanded(
                    child: InkWell(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14,horizontal: 12),
                        height: 48,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                            border: Border.all(width: 1,color: Color.fromRGBO(177, 177, 177, 1))
                        ),
                        child: Text(
                          "... "+
                              // AppLocalizations.of(context)!.to+
                              (dates_two.length!=0 ?
                              (((dates_two.first as DateTime).day<10 ? "0"+(dates_two.first as DateTime).day.toString() : (dates_two.first as DateTime).day.toString())+"."+
                                  ((dates_two.first as DateTime).month<10 ? "0"+(dates_two.first as DateTime).month.toString() : (dates_two.first as DateTime).month.toString())+"."+
                                  (dates_two.first as DateTime).year.toString()) : ""),
                          style: TextStyle(fontFamily: "SFPro",fontWeight: FontWeight.w500,color: Color.fromRGBO(98, 98, 98, 1)),
                        ),
                      ),
                      onTap: (){
                        setState((){
                          CalendarIndex=1;
                          ShowCallendar=true;
                        });
                      },
                    ),
                  )
                ],
              ),
              SizedBox(height: 12),
              PriceFilterToggle(),
            ]
          ],
        ),
      ),
    );
  }
}





Widget EventCardForDeveloper({required context,required data,required russian_language}){

// Widget EventCard(context,header,img,price,is_online,is_indoor,address,peoples,maxpeoples,date,min){
  return Container(
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12,spreadRadius: 4,blurRadius: 20)
        ]
    ),
    padding: EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: MediaQuery.of(context).size.width>700 ? 300 : 160,
          child: Stack(
            children: [

              Container(
                height: MediaQuery.of(context).size.width>700 ? 300 : 160,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black12,
                    image: DecorationImage(
                      image: NetworkImage(data['photo_link']),
                      fit: BoxFit.cover,
                    )
                ),
              ),
              if((data as Map).containsKey("approved"))...[
                if(!data["approved"]) ...[
                  Positioned(
                      top: 8,left: 8,
                      child: Column(
                        children: [
                          if((data as Map).containsKey("approved"))...[
                            if(data["approved"]) ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(width: 1,color: Colors.white),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 12,vertical: 4),
                                child: Row(
                                  children: [
                                    Text("Waiting",style: TextStyle(fontWeight: FontWeight.w700,color: Colors.white,fontSize: 12),)
                                  ],
                                ),
                              ),
                              SizedBox(width: 8,)
                            ]
                          ],
                        ],
                      )
                  ),
                ]
              ],

              Positioned(
                bottom: 8,left: 8,
                child: Row(
                  children: [
                    if(!data['is_online']) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(width: 1,color: Colors.grey),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12,vertical: 4),
                        child: Row(
                          children: [
                            Image.asset("lib/assets/Icons/BoldPng/Location.png",width: 12,),
                            SizedBox(width: 4,),
                            (data as Map).containsKey("short_address") ?
                            Text(data['short_address'].length<16 ? data['short_address'].toUpperCase() : data['short_address'].substring(0,16).toUpperCase()+"...",style: TextStyle(fontWeight: FontWeight.w700,color: Colors.white,fontSize: 12),) :
                            Text(data['address'].length<16 ? data['address'].toUpperCase() : data['address'].substring(0,16).toUpperCase()+"...",style: TextStyle(fontWeight: FontWeight.w700,color: Colors.white,fontSize: 12),),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                    ],
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(width: 1,color: Colors.grey),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12,vertical: 4),
                      // child: Text(data['is_online'] ? AppLocalizations.of(context)!.online.toUpperCase() : data['is_indor'] ? AppLocalizations.of(context)!.indoor.toUpperCase() : AppLocalizations.of(context)!.outdoor.toUpperCase(),style: TextStyle(fontWeight: FontWeight.w700,color: Colors.white,fontSize: 12),),
                      child: Text(data['is_online'] ? 'ONLINE' : data['is_indor'] ? 'INDOOR' : 'OUTDOOR',style: TextStyle(fontWeight: FontWeight.w700,color: Colors.white,fontSize: 12),),
                    ),
                  ],
                ),
              ),
              if(data.containsKey("show_flag")&&data.containsKey("primary_language")) ...[
                if(data['show_flag']&&data['primary_language']!="All languages") Positioned(
                  top: 8,right: 8,
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(width: 1,color: Colors.grey),
                            image: DecorationImage(
                                image: data['primary_language']=="English" ? AssetImage("lib/assets/Flag/EngFlag.png")
                                    :  data['primary_language']=="American English" ? AssetImage("lib/assets/Flag/UsFlag.png")
                                    :  data['primary_language']=="Русский" ? AssetImage("lib/assets/Flag/RusFlag.png")
                                    :  data['primary_language']=="Українська" ? AssetImage("lib/assets/Flag/UkrFlag.png")
                                    :  data['primary_language']=="Қазақ" ? AssetImage("lib/assets/Flag/KazFlag.png")
                                    :  data['primary_language']=="հայերեն" ? AssetImage("lib/assets/Flag/ArmFlag.png")
                                    : AssetImage("lib/assets/Flag/EngFlag.png")
                            )
                        ),
                        width: 32,
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ]
            ],
          ),
        ),
        SizedBox(height: 12,),
        Text(russian_language&&data['rus_header']!="" ? data['rus_header'].toString() : data['header'].toString(),style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),),
        SizedBox(height: 8),
        Row(
          children: [
            IconText(DateTime.fromMillisecondsSinceEpoch(data['date']).hour.toString()+":"+(DateTime.fromMillisecondsSinceEpoch(data['date']).minute>9 ? DateTime.fromMillisecondsSinceEpoch(data['date']).minute.toString() : "0"+DateTime.fromMillisecondsSinceEpoch(data['date']).minute.toString() )+
                " | "+data['duration'].toString()+" min.","TimeSquare.png"),
            SizedBox(width: 16,),
            data['price']=="0" ?

            IconText("FREE","Wallet.png") :
            IconText("\$"+data['price'].toString(),"Wallet.png"),
            if(data.containsKey("infinity_users")) ...[
              if(!data['infinity_users'])...[
                SizedBox(width: 16,),
                data['unlimited_users'] ? IconText(""+data['max_peoples'].toString(),"Users.png") : IconText(data['peoples'].toString()+"/"+data['max_peoples'].toString(),"Users.png")
              ],
            ] else ...[
              SizedBox(width: 16,),
              data['unlimited_users'] ? IconText(""+data['max_peoples'].toString(),"Users.png") : IconText(data['peoples'].toString()+"/"+data['max_peoples'].toString(),"Users.png")
            ]
          ],
        )
      ],
    ),
  );
}

Widget IconText(text,icon){
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset("lib/assets/Icons/LightPng/"+icon,width: 24,height: 24,color: Colors.black54),
      SizedBox(width: 6,),
      Text(text,style: TextStyle(fontSize: 14,fontWeight: FontWeight.w600,color: Colors.black54),),
    ],
  );
}


Widget ProfileAvatar(doc_id){
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  return FutureBuilder(
      future: firestore.collection("UsersCollection").doc(doc_id).snapshots().first,
      builder: (context,snapshot){

        if(snapshot.hasData){
          if(snapshot.data!.get("avatar_link")=="https://mygardenia.ru/uploads/pers1.jpg"){
            return Container(

              height: 28,
              width: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                image: DecorationImage(
                    image: AssetImage('lib/assets/avatar.png'),fit: BoxFit.cover
                ),
              ),
            );
          } else {
            // return CircleAvatar(
            //   backgroundColor: Colors.grey,
            //   backgroundImage: NetworkImage(snapshot.data!.get("avatar_link")),
            // );
            return Container(
              width: 28,
              height: 28,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.network(snapshot.data!.get("avatar_link"),
                  fit: BoxFit.cover,
                  loadingBuilder: (context,child,loadingProgress){
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },),
              ),
            );
          }
        } else {
          return Container(
            height: 28,
            width: 28,
            // child: Image.asset('lib/images/men_avatar.png'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              image: DecorationImage(
                  image: AssetImage('lib/assets/avatar.png'),fit: BoxFit.cover
              ),
            ),
          );;
        }

      }
  );
}