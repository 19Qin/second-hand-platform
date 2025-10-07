import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';

class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).userAgreement),
        backgroundColor: const Color(0xFF32C286),
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AgreementSection(
              title: 'I. Agreement Overview',
              content: 'This Agreement is a legal agreement between you ("User") and [Platform Name] ("Platform") regarding the use of Platform services. By registering, logging in, or using the Platform services, you agree to all terms and conditions of this Agreement. If you do not agree with any part of this Agreement, please do not register or use the Platform services.',
            ),
            
            _AgreementSection(
              title: 'II. Definitions',
              content: '''Platform: Refers to the second-hand goods trading platform operated by [Company Name], including its website and mobile applications.

User: Refers to any individual or entity that registers and uses the Platform services.

Dynamic Verification Code: Refers to a 4-digit random number sent by the Platform to the user's reserved Australian mobile phone number for transaction identity verification and completion, valid for 30 minutes only, and can be used only once per order.

Transaction Completion: Refers to the process where the seller enters the dynamic verification code provided by the buyer into the Platform application, and the system confirms the transaction status as "Completed".

Electronics Recycling Service: Refers to the electronics recycling service provided by the Platform, allowing users to transact with verified recyclers.''',
            ),
            
            _AgreementSection(
              title: 'III. Registration and Account Management',
              content: '''Registration Requirements: Users must register using a valid Australian mobile phone number. The Platform will verify the legality of the mobile phone number through SMS. Users must ensure that the provided mobile phone number is true, accurate, and valid.

Account Security: After successful registration, users will receive an account and password. Users must protect their account and password and are responsible for all activities conducted through that account. If users discover that their account has been compromised, they must immediately notify the Platform. The Platform has the right to take necessary measures to protect account security, including but not limited to temporarily freezing accounts.

Account Violation Handling: The Platform will monitor user accounts and has the right to immediately ban relevant accounts for discovered fraudulent transactions or fraudulent behavior. For minor violations such as non-delivery or non-payment, the Platform will issue one warning. If similar behavior occurs again, the Platform has the right to directly ban the account without bearing any responsibility. Banned accounts cannot be re-registered for use on the Platform.

Age Requirements: Users must be at least 18 years old to register and use the Platform services. If you are under 18 years old, you must obtain consent from your parents or legal guardians.''',
            ),
            
            _AgreementSection(
              title: 'IV. Transaction Process and Dynamic Verification Code',
              content: '''Transaction Process:
(1) Buyer browses products and selects to purchase;
(2) After buyer places an order, the Platform sends a 4-digit dynamic verification code to the buyer's reserved Australian mobile phone number;
(3) After buyer confirms receipt of the verification code, provides it to the seller;
(4) After seller receives the verification code, provides the product to the buyer;
(5) After buyer confirms the product is correct, provides the verification code to the seller;
(6) Seller enters the verification code in the Platform application, and the system confirms the transaction status as "Completed".

Legal Effect: The dynamic verification code is a necessary condition for completing transactions and has the same legal effect as a written signature, indicating that the user has confirmed the transaction content and agreed to complete the transaction.

Expiration Handling: The verification code is valid for 30 minutes. If it expires, a new verification code must be requested. If the buyer does not provide the verification code to the seller within 30 minutes, the Platform will invalidate it and may contact the buyer to confirm if a new verification code is needed.''',
            ),
            
            _AgreementSection(
              title: 'V. Payment Methods and Cash Payment',
              content: '''Cash Payment: The Platform supports cash payment. After transaction completion, the buyer should pay the agreed price to the seller. To ensure transaction security and traceability, the buyer should submit payment receipt screenshots through the Platform APP after the transaction, including transaction time, location, and amount.

Record Retention: The Platform will retain transaction records for at least 2 years to resolve potential disputes.

Anti-Money Laundering/Counter-Terrorism Financing Compliance: The Platform may implement anti-money laundering and counter-terrorism financing measures as required by AUSTRAC. Large cash transactions (such as exceeding AUD 10,000) may be reported to relevant authorities.''',
            ),
            
            _AgreementSection(
              title: 'VI. Product Listing and Trading',
              content: '''Product Listing Requirements: Users must ensure that product descriptions are true, accurate, and complete, and must not publish false information. For electronic products, users should disclose usage conditions, battery performance, and any defects.

Platform Rights: The Platform may review, modify, or delete information published by users to ensure transaction security. Violations may result in warnings, functional restrictions, or account bans.''',
            ),
            
            _AgreementSection(
              title: 'VII. Special Terms for Electronics Recycling Services',
              content: '''Recycler Qualifications: Recyclers must hold valid business qualifications and comply with Australian e-waste laws. The Platform reserves the right to review qualifications.

Data Erasure: The Platform does not erase personal information from devices. Users are responsible for deleting personal data before transactions. The Platform is not responsible for data breaches caused by user negligence.''',
            ),
            
            _AgreementSection(
              title: 'VIII. Consumer Protection under Australian Consumer Law (ACL)',
              content: '''Acceptable Quality: Products sold must be of acceptable quality, including being safe, durable, and consistent with descriptions.

Major Failures: If a product has major defects, the buyer has the right to receive a full refund or replacement.

Minor Failures: If a product has minor issues, the seller must repair or remedy within a reasonable time; otherwise, the buyer may request a refund or replacement.

Platform Role: The Platform primarily acts as a market facilitator. However, in cases of fraud or misrepresentation, it may intervene in disputes, including freezing accounts or requiring refunds.''',
            ),
            
            _AgreementSection(
              title: 'IX. Privacy Policy',
              content: '''Data Collection: The Platform may collect mobile phone numbers, transaction information, device locations, and user behavior data.

Data Storage and Protection: Data is stored on AWS with international certifications (ISO 27001, SOC 2). Reasonable measures will be taken to protect data.

Data Retention: Transaction and verification data will be stored for at least 2 years, not exceeding 7 years.

Cookies: The Platform may use cookies or similar technologies to enhance user experience. Users can disable them, but some features may be limited.

Cross-Border Transfer: Data may be transferred outside Australia using SCC to ensure compliance with Australian Privacy Principles (APPs).

Data Breach Notification: In the event of a notifiable data breach, the Platform will notify OAIC and affected users within 72 hours as required by the Privacy Act.

User Rights: Users may request access, correction, deletion of their personal data and information about its use and disclosure. If dissatisfied, complaints may be made to OAIC.''',
            ),
            
            _AgreementSection(
              title: 'X. Platform Responsibilities and Disclaimers',
              content: '''The Platform only acts as an intermediary to facilitate transactions between users and does not guarantee product quality, descriptions, or suitability.

The Platform may take enforcement actions against fraudulent or illegal activities, including account suspension or listing deletion.

For recycling services, the Platform is not responsible for device valuation, inspection, or environmental processing.

Users must clear all personal data before device handover. The Platform is not responsible for data breaches caused by user negligence.

To the extent permitted by law, the Platform is not liable for direct, indirect, or consequential losses caused by user behavior, third-party behavior, technical failures, or force majeure.''',
            ),
            
            _AgreementSection(
              title: 'XI. Dispute Resolution',
              content: '''Users must first attempt to resolve disputes through Platform customer service.

If resolution is not possible, users may complain to the Australian Competition and Consumer Commission (ACCC) or relevant regulatory authorities.

Parties may agree to third-party mediation or arbitration.

If still unresolved, disputes will be submitted to courts with jurisdiction in the state where the Platform is registered.''',
            ),
            
            _AgreementSection(
              title: 'XII. Agreement Updates and Applicable Law',
              content: '''Updates: The Platform may update this Agreement to comply with changes in Australian law. Users will be notified of updates through announcements or application notifications. Continued use constitutes acceptance.

Governing Law: This Agreement is governed by Australian federal law and relevant state laws. If any terms conflict with Australian law, the law shall prevail.''',
            ),
            
            _AgreementSection(
              title: 'XIII. Contact Us',
              content: '''If you have questions about this Agreement, please contact:

Email: Auwei@Auwei.net

Phone: +61 435103599

Important Note: This Agreement has been drafted in accordance with the Australian Privacy Act 1988 (as amended in 2022), the Competition and Consumer Act 2010, and other relevant laws and regulations. The Platform will conduct regular compliance reviews to ensure this Agreement remains current.''',
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _AgreementSection extends StatelessWidget {
  final String title;
  final String content;

  const _AgreementSection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF32C286),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
