trigger ClientTrigger on Contact (before insert, before update, after insert, after update, after delete) {

	if (Trigger.isBefore) {
		IntakeServicesTrigger.get().updateContactAge( Trigger.New, Trigger.oldMap );
	} else {
		if (Trigger.isDelete)
			IntakeServicesTrigger.get().fixHouseholdForContactChange( Trigger.Old, Trigger.oldMap, true );
		else
			IntakeServicesTrigger.get().fixHouseholdForContactChange( Trigger.New, Trigger.oldMap, false );
	}

}