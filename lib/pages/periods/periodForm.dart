import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fund_tracker/models/period.dart';
import 'package:fund_tracker/services/databaseWrapper.dart';
import 'package:fund_tracker/shared/constants.dart';
import 'package:fund_tracker/shared/library.dart';
import 'package:fund_tracker/shared/loader.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class PeriodForm extends StatefulWidget {
  final Period period;

  PeriodForm(this.period);

  @override
  _PeriodFormState createState() => _PeriodFormState();
}

class _PeriodFormState extends State<PeriodForm> {
  final _formKey = GlobalKey<FormState>();

  String _name;
  DateTime _startDate;
  String _durationValue = '';
  DurationUnit _durationUnit;
  bool _isDefault;

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final _user = Provider.of<FirebaseUser>(context);
    final isEditMode = widget.period.pid != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Period' : 'Add Period'),
        actions: isEditMode
            ? <Widget>[
                FlatButton(
                  textColor: Colors.white,
                  child: Icon(Icons.delete),
                  onPressed: () async {
                    setState(() => isLoading = true);
                    DatabaseWrapper(_user.uid).deletePeriod(widget.period);
                    Navigator.pop(context);
                  },
                )
              ]
            : null,
      ),
      body: isLoading
          ? Loader()
          : Container(
              padding: EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 50.0,
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    SizedBox(height: 20.0),
                    FlatButton(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text('Start Date:                         '),
                          Text(
                              '${getDate(_startDate ?? widget.period.startDate)}'),
                          Icon(Icons.date_range),
                        ],
                      ),
                      onPressed: () async {
                        DateTime startDate = await showDatePicker(
                          context: context,
                          initialDate: new DateTime.now(),
                          firstDate: DateTime.now().subtract(
                            Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            Duration(days: 365),
                          ),
                        );
                        if (startDate != null) {
                          setState(() => _startDate = startDate);
                        }
                      },
                    ),
                    SizedBox(height: 20.0),
                    TextFormField(
                      initialValue: widget.period.name,
                      validator: (val) {
                        if (val.isEmpty) {
                          return 'Enter a name for this period.';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Name',
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (val) {
                        setState(() => _name = val);
                      },
                    ),
                    SizedBox(height: 20.0),
                    TextFormField(
                      initialValue: widget.period.durationValue != null
                          ? widget.period.durationValue.toString()
                          : '',
                      autovalidate: _durationValue.isNotEmpty,
                      validator: (val) {
                        if (val.isEmpty) {
                          return 'Enter a value for the duration.';
                        } else if (val.contains('.')) {
                          return 'This value must be an integer.';
                        } else if (int.parse(val) <= 0) {
                          return 'This value must be greater than 0';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Duration',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        setState(() => _durationValue = val);
                      },
                    ),
                    SizedBox(height: 20.0),
                    DropdownButton<DurationUnit>(
                      items: DurationUnit.values.map((unit) {
                        return DropdownMenuItem<DurationUnit>(
                          value: unit,
                          child: Text(unit.toString().split('.')[1]),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _durationUnit = val);
                      },
                      value: _durationUnit ?? widget.period.durationUnit,
                      isExpanded: true,
                    ),
                    SizedBox(height: 20.0),
                    SwitchListTile(
                        title: Text('Set to default (allowed: 1)'),
                        value: _isDefault ?? widget.period.isDefault,
                        onChanged: (val) {
                          setState(() => _isDefault = val);
                        }),
                    SizedBox(height: 20.0),
                    RaisedButton(
                      color: Theme.of(context).primaryColor,
                      child: Text(
                        isEditMode ? 'Save' : 'Add',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState.validate()) {
                          Period period = Period(
                            pid: widget.period.pid ?? new Uuid().v1(),
                            name: _name ?? widget.period.name,
                            startDate: _startDate ?? widget.period.startDate,
                            durationValue: _durationValue != ''
                                ? int.parse(_durationValue)
                                : widget.period.durationValue,
                            durationUnit:
                                _durationUnit ?? widget.period.durationUnit,
                            isDefault: _isDefault ?? widget.period.isDefault,
                            uid: _user.uid,
                          );

                          setState(() => isLoading = true);
                          isEditMode
                              ? DatabaseWrapper(_user.uid).updatePeriod(period)
                              : DatabaseWrapper(_user.uid).addPeriod(period);

                          if (period.isDefault) {
                            DatabaseWrapper(_user.uid).setRemainingNotDefault(period);
                          }
                          Navigator.pop(context);
                        }
                      },
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
