import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddPackageForm extends StatefulWidget {
  const AddPackageForm({super.key});

  @override
  _AddPackageFormState createState() => _AddPackageFormState();
}

class _AddPackageFormState extends State<AddPackageForm> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  double? price;
  DateTime? expireDate; // Make expireDate nullable

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Investment Package')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Package Title'),
                onChanged: (val) {
                  title = val;
                },
                validator: (val) => val!.isEmpty ? 'Enter a title' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (val) {
                  description = val;
                },
                maxLines: 3,
                validator: (val) => val!.isEmpty ? 'Enter a description' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  price = double.tryParse(val);
                },
                validator: (val) => val!.isEmpty || price == null || price! <= 0
                    ? 'Enter a valid price'
                    : null,
              ),
              GestureDetector(
                child: ListTile(
                  title: Text(
                    expireDate == null
                        ? 'Select Expire Date'
                        : 'Expires on: ${expireDate!.toLocal()}'.split(' ')[0],
                  ),
                  trailing: const Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      expireDate = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() && expireDate != null) {
                    final docRef =
                        FirebaseFirestore.instance.collection('packages').doc();

                    await docRef.set({
                      'packageId': docRef.id,
                      'title': title,
                      'description': description,
                      'price': price,
                      'expireDate': expireDate,
                      'isActive': false,
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Package added successfully!'),
                      ),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Please fill all fields and select a date'),
                      ),
                    );
                  }
                },
                child: const Text('Add Package'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
