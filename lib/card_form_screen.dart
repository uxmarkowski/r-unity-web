import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_web/sign_in.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '/blocs/blocs.dart';


class CardFormScreen extends StatefulWidget {
  final type;
  final price;
  const CardFormScreen({Key? key,required this.type,required this.price}) : super(key: key);

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {


  TextEditingController BalanceController=TextEditingController();

  bool NeedSaveMyCard=false;

  FocusNode BalanceNode=FocusNode();
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  void UpDateBalace() async{
    var user_info=await firestore.collection("UsersCollection").doc(_auth.currentUser!.phoneNumber).get();

    if(widget.type=="balance"){
      await firestore.collection("UsersCollection").doc(_auth.currentUser!.phoneNumber).update({
        "balance":user_info.data()!['balance']+int.parse(BalanceController.text),
        // "balance":int.parse("BalanceController.text"),
      });
    } else if(widget.type=="event") {
      Navigator.pop(context,true);
    }


  }


  @override
  Widget build(BuildContext context) {
    widget.type=="event" ? BalanceController.text=widget.price : null;

    return Scaffold(
      // appBar: AppBarPro(AppLocalizations.of(context)!.buy_ticket),
      appBar: AppBarPro("Buy ticket"),
      body: SingleChildScrollView(
        child: InkWell(
          onTap: (){ BalanceNode.hasFocus ? BalanceNode.unfocus() : null; },
          child: Padding(
            padding: EdgeInsets.only(top: 24,left: 16,right: 16),
            child: BlocBuilder<PaymentBloc, PaymentState>(
              builder: (context, state) {
                if(state.status==PaymentStatus.success) UpDateBalace();

                CardFormEditController controller = CardFormEditController(
                  initialDetails: state.cardFieldInputDetails,
                );

                if (state.status == PaymentStatus.initial) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 36,top: 36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          // AppLocalizations.of(context)!.card_form,
                          'Card Form',
                          style: TextStyle(fontSize: 24,fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            // color: Colors.black,
                          ),
                          child: Column(
                            children: [
                              CardFormField(
                                controller: controller,
                                style: CardFormStyle(backgroundColor: MediaQuery.of(context).platformBrightness!=Brightness.dark ? Colors.white : Colors.black,textColor: Colors.grey,placeholderColor: Colors.white,textErrorColor: Colors.white,borderRadius: 12),
                              ),
                              // BalanceFormPro(BalanceController, BalanceNode, AppLocalizations.of(context)!.summ, 0, true, "\$",context),
                              BalanceFormPro(BalanceController, BalanceNode, "Summ", 0, true, "\$", context),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // ButtonPro(AppLocalizations.of(context)!.pay, () {
                        ButtonPro("Pay", () {
                          if(widget.type!="balance"){
                            if (controller.details.complete) {
                              context.read<PaymentBloc>().add(
                                const PaymentCreateIntent(
                                  billingDetails: BillingDetails(
                                    email: 'massimo@maxonflutter.com',
                                  ),
                                  items: [
                                    {'id': '100'},
                                  ],
                                ),
                              );
                            } else {
                              // ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(AppLocalizations.of(context)!.the_form_is_not_complete),),);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The form is not complete.'),),);
                            };
                          } else {
                            print(controller.details.complete.toString());
                            print(BalanceController.text.length.toString());

                            if (controller.details.complete&&BalanceController.text.length!=0) {
                              context.read<PaymentBloc>().add(
                                PaymentCreateIntent(
                                  billingDetails: BillingDetails(
                                    email: 'massimo@maxonflutter.com',
                                  ),
                                  items: [
                                    {'id': BalanceController.text},
                                  ],
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text("The form is not complete"),),);
                            };
                          }

                        }
                        ,false),
                        // const SizedBox(height: 4),
                        // GestureDetector(
                        //   onTap: (){
                        //     setState(() {
                        //       NeedSaveMyCard=!NeedSaveMyCard;
                        //       print(controller.details.number.toString());
                        //       print(controller.details.cvc.toString());
                        //       print(controller.details.expiryMonth.toString());
                        //       print(controller.details.number.toString());
                        //     }
                        //     );
                        //   },
                        //   child: Row(
                        //     crossAxisAlignment: CrossAxisAlignment.center,
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     children: [
                        //       Checkbox(
                        //           value: NeedSaveMyCard,
                        //           onChanged: (value){
                        //
                        //           },
                        //       ),
                        //       Text("Save my card",style: TextStyle(fontWeight: FontWeight.w800,fontSize: 16,color: Colors.black),),
                        //       SizedBox(width: 16)
                        //     ],
                        //   ),
                        // ),

                      ],
                    ),
                  );
                }
                if (state.status == PaymentStatus.success) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Text(AppLocalizations.of(context)!.the_payment_is_successful),
                      const Text('The payment is successful.'),
                      const SizedBox(
                        height: 10,
                        width: double.infinity,
                      ),
                      ButtonPro(
                          // AppLocalizations.of(context)!.open_form,
                          'Open form',
                              (){
                        context.read<PaymentBloc>().add(PaymentStart());
                      },false),
                      // ElevatedButton(
                      //   onPressed: () {
                      //     context.read<PaymentBloc>().add(PaymentStart());
                      //   },
                      //   child: const Text('Back to Home'),
                      // ),
                    ],
                  );
                }
                if (state.status == PaymentStatus.failure) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Text(AppLocalizations.of(context)!.the_payment_failed),
                      Text('The payment failed.'),
                      const SizedBox(
                        height: 16,
                        width: double.infinity,
                      ),
                      ButtonPro(
                          // AppLocalizations.of(context)!.try_again,
                          'Try again',
                              (){
                        context.read<PaymentBloc>().add(PaymentStart());
                      },false),
                      // ElevatedButton(
                      //   onPressed: () {
                      //     context.read<PaymentBloc>().add(PaymentStart());
                      //   },
                      //   child: const Text('Try again'),
                      // ),
                    ],
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}



Widget BalanceFormPro(controller,node,hint,margin,textfield,suffix,context) {

  return Container(
    width: double.infinity,
    margin: EdgeInsets.only(bottom: margin.toDouble()),
    padding: EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
        color: MediaQuery.of(context).platformBrightness!=Brightness.dark ? Colors.white : Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 1,color: MediaQuery.of(context).platformBrightness==Brightness.dark ? Colors.white.withOpacity(0.16) : Colors.black.withOpacity(0.16))
    ),
    child: TextFormField(
      maxLines: null,
      focusNode: node,
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(fontWeight: FontWeight.w700,color: MediaQuery.of(context).platformBrightness==Brightness.dark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontWeight: FontWeight.w400,color: MediaQuery.of(context).platformBrightness==Brightness.dark ? Colors.white : Colors.black),
        suffix: Text(suffix,style: TextStyle(fontWeight: FontWeight.w700,color: MediaQuery.of(context).platformBrightness==Brightness.dark ? Colors.white : Colors.black),),
        border: InputBorder.none,
      ),
    ),
  );
}