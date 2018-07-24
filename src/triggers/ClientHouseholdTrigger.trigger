trigger ClientHouseholdTrigger on Account (before update, before insert) {

	if (Trigger.isBefore) {
		IntakeServicesTrigger.get().updateProofDates( Trigger.New, Trigger.oldMap );
	}

}