@isTest
public with sharing class IntakeServicesStatsTest {

	@isTest
	private static void testIntakeServicesStats() {

		// insert a household and a visit for today
        Account hh = new Account(
			Name = 'Test Account',
			C501_IS_Inactive__c = false
			);

		// insert a contact
        Contact contact = new Contact(
			Lastname = 'Test Lastname'
			);

        hh = IntakeServices.saveHousehold(hh);

		Intake_Services_Checkin__c checkin1 = new Intake_Services_Checkin__c(
			Name = hh.Id,
            Points_Remaining__c = 15,
            Box_Size__c = 'small',
            Check_In_Time__c = Datetime.now()
        );

		insert checkin1;
		
        Map<String, Integer> commU = new Map<String, Integer>();
        Id cVId = IntakeServices.logVisit(hh.Id, contact.Id, 'small', 1.5, 5, commU, 'These are notes', new List<String> {'Housing Intake'}, new List<String>{'Childcare'});

		ApexPages.CurrentPage().getParameters().put('tfcode','TODAY');
		IntakeServicesStats fbs = new IntakeServicesStats();
		fbs.loadStats();
		fbs.queryStats('TODAY');
	}

}