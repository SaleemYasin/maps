import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        centerTitle: true,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Effective Date: 16-12-2024',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                '1. Acceptance of Terms\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                'By accessing or using our services, including subscribing to investment packages, you agree to comply with and be bound by these Terms and Conditions. If you do not agree to these terms, you must refrain from using our services. ',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '2. Fixed Deposit Product Overview\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                'MAPS offers a Fixed Deposit with a minimum investment period of 6 months. Key details are as follows:\n'
                '• Investment Period: 6 months\n'
                '• Earning Rate: The earning rate ranges from 6% to 12% per annum, adjusted monthly '
                'based on the company’s profit rate.\n',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '3. Fixed Deposit Product Overview\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '• Deposit Deadline: To receive profits for the next month, you must deposit your amount before the 15th of the current month.\n'
                '• Profit Distribution: If your deposit is made before the 15th, you will receive your earnings on the 10th of the next month.\n'
                '• No Profit for Late Deposits: Deposits made after the 15th of the month will not be eligible for profit in the next cycle (i.e., on the 10th of the next month).\n'
                '• Monthly Cycle: Our monthly profit cycle runs from the 10th of one month to the 10th of the next month. ',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '4. Investment Packages\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '• MAPS offers various investment packages to cater to different investor needs. Each package comes with specific terms, returns, and eligibility criteria.\n'
                '• Subscription Limit: A single user can subscribe to any given investment package no more than 3 times.\n'
                '• Once the limit of 3 subscriptions to a particular package is reached, you will no longer be able to invest in that specific package. However, you may choose to subscribe to other available packages.\n',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '5.  Invoice for Deposited Amount\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '• Upon depositing your funds, you will receive an invoice for the deposited amount, which includes details such as the amount deposited, the earning rate, and the investment package chosen.\n'
                '• This invoice will be sent to you through email, WhatsApp message, or an SMS to the mobile number you provided during registration.\n'
                '• Once the limit of 3 subscriptions to a particular package is reached, you will no longer be able to invest in that specific package. However, you may choose to subscribe to other available packages.\n',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '6.  Withdrawal of Earnings\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '• You may withdraw the earned money on your deposit every 15 days.\n'
                '• The principal amount can only be withdrawn after the full 6-month term has passed.\n',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '7.  Early Withdrawal in Case of Emergency\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '• If you face an emergency, you may request early withdrawal of your principal and credited earnings after 1 month from your request date, provided you submit a genuine reason for the emergency.\n'
                '• Early withdrawal requests will be evaluated at our discretion.\n',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '8.  Risk Acknowledgment\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '• You acknowledge that all investments carry inherent risks. The earning rate is subject to fluctuations based on the company’s profitability, which may affect your earning.\n',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '9.  Privacy Policy\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '• We are committed to protecting your privacy and handling your personal information in accordance with our Privacy Policy.\n',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'By using our services, you acknowledge that you have read, understood, and agree to these Terms and Conditions. \n'
                '',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'For any inquiries, contact us at maps3333333@gmail.com!. \n',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
