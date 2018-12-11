@isTest(SeeAllData=false)
public with sharing class IntakeServicesTest {

    @isTest
    private static void testCheckOutIn() {
        // New Household insert then update
        Account cHh = new Account(
            Name = 'Test Account'
        );
        insert(cHh);

        // New contact nsert then update
        Contact cContact = new Contact(
            Lastname = 'Test Lastname'
        );
        insert(cContact);

        Map<String, Integer> commU = new Map<String, Integer>();
        commU.put('Meat', 2);
        commU.put('Bread', 1);

        // Test CheckIn & CheckOut
        IntakeServices.checkIn(cHh.Id, cContact.Id, commU, 'Notes', false, 'Other', '2018-01-01', new List<String> {'Housing Pool'}, new List<String>{'Energy Assistance'}, 'Bellingham');
        System.assert(Intake_Services_Checkin__c.getInstance(cHh.Id + 'Bellingham') != null);

        // Attempt to CheckIn again should not throw error and just update existing record
        IntakeServices.checkIn(cHh.Id, cContact.Id, commU, 'Notes', false, 'Other', '2018-01-01', new List<String> {'Housing Pool'}, new List<String>{'Energy Assistance'}, 'Bellingham');

        IntakeServices.cancelCheckIn(cHh.Id);
        System.assert(Intake_Services_Checkin__c.getInstance(cHh.Id + 'Bellingham') == null);
    }

    @isTest
    private static void testSaveHouseHold() {
        Account cHh = new Account(
            Name = 'Test Account',
            C501_IS_Inactive__c = false
        );
        
        // Check insert of Household
        Account cHh0 = new Account(Name = 'Test Account');
        cHh0 = IntakeServices.saveHousehold(cHh);
        System.assert(cHh0.Id != null, 'Id should not be null');

        // Check update of Household
        cHh.BillingStreet = '101 1st St';
        cHh0 = IntakeServices.saveHousehold(cHh);
        System.assert(cHh0.BillingStreet == cHh.BillingStreet, 'Method did not update Household: ' + cHh0.C501_IS_Children__c);

        // Insert Client
        Contact c1 = new Contact( AccountId = null, LastName = 'Test1', Birthdate = System.today().addyears(-50) );
        cHh0 = IntakeServices.saveHouseholdMembers(cHh.Id, new List<Contact> { c1 });
        System.assert(cHh0.Name != null, 'Method did not update Household: ' + cHh0.Name);

        // Update Client
        c1.FirstName = 'Test2';
        cHh0 = IntakeServices.saveHouseholdMembers(cHh.Id, new List<Contact> { c1 });
        System.assert(cHh0.Name != null, 'Method did not update Household: ' + cHh0.Name);
        System.debug('***** Client Name: ' + cHh0.Name);
        System.debug('***** Inactive: ' + cHh0.C501_IS_Inactive__c);

        List<IntakeServices.ClientHousehold> cHs = IntakeServices.queryHouseholds(cHh0.Name);
// TODO     // System.assertEquals(1, cHs.size(), 'Could not find: ' + cHh0.Name);   

        // Save new Household and Client
        Account cHh1 = new Account(
            Name = 'Test Account'
        );
        Contact c2 = new Contact( AccountId = null, LastName = 'Test1', Birthdate = System.today().addyears(-50) );
        Account cHh2 = IntakeServices.saveHouseholdAndMembers(cHh1, new List<Contact> { c2 });       
        System.assert(cHh2.Id != null, 'Id should not be null');
        
        IntakeServices.AppSettings appSettings = IntakeServices.getAppSettings();
        System.assert(appSettings.general != null);
    }


	@isTest
	private static void testCheckInsVisits() {
		Account household1 = new Account(
            Name = 'Test Account',
			C501_IS_Inactive__c = false
		);
		
		// insert a contact
        Contact contact = new Contact(
			Lastname = 'Test Lastname'
			);
        
		// Check insert of Household
		household1 = IntakeServices.saveHousehold(household1);

		Intake_Services_Checkin__c checkin1 = new Intake_Services_Checkin__c(
			Name = household1.Id,
			C501_IS_Visitor__c = contact.Id,
            Points_Remaining__c = 15,
            Box_Size__c = 'small',
            Check_In_Time__c = Datetime.now(),
            C501_With_Staff__c = false
        );

		insert checkin1;

		Account household2 = new Account(
            Name = 'Test Account',
			C501_IS_Inactive__c = false
		);
		
		// Check insert of Household
		household2 = IntakeServices.saveHousehold(household2);

		Intake_Services_Checkin__c checkin2 = new Intake_Services_Checkin__c(
			Name = household2.Id,
			C501_IS_Visitor__c = contact.Id,
            Points_Remaining__c = 15,
            Box_Size__c = 'small',
            Check_In_Time__c = Datetime.now(),
            C501_With_Staff__c = false
        );
		insert checkin2;

		Account household3 = new Account(
            Name = 'Test Account',
			C501_IS_Inactive__c = false
		);
		
		// Check insert of Household
		household3 = IntakeServices.saveHousehold(household3);

		Intake_Services_Checkin__c checkin3 = new Intake_Services_Checkin__c(
			Name = household2.Id,
			C501_IS_Visitor__c = contact.Id,
            Points_Remaining__c = 15,
            Box_Size__c = 'small',
            Check_In_Time__c = Datetime.now(),
            C501_With_Staff__c = true
        );
		insert checkin3;

		//List<IntakeServices.ClientCheckin> cc = IntakeServices.getCheckedInList();
		//System.assertEquals(2, cc.size(), 'Two households are currently checked in');

		//List<IntakeServices.ClientCheckin> ccWithStaff = IntakeServices.getCheckedInListWithStaff();
		//System.assertEquals(1, ccWithStaff.size(), 'One household is currently with staff');

		Map<String, Integer> commU = new Map<String, Integer>();
		commU.put('Meat', 2);
		commU.put('Bread', 1);
		Id cVId = IntakeServices.logVisit(household1.Id, contact.Id, 'small', 1.1, 5, commU, 'Other', '2018-01-01', 'These are notes', new List<String> {'Housing Pool'}, new List<String>{'Energy Assistance'}, 'Bellingham', 'Intake');
		System.assert(cVId != null);

		List<Client_Visit__c> cV = IntakeServices.getVisitHistory(household1.Id);
		System.assert(cV.size() == 1);	

		C501_Service_Household__c serviceHousehold = new C501_Service_Household__c(
			Name = household1.Id,
            C501_Service_Id__c = household1.Id, 
			C501_Household__c = household1.Id
        );
		insert serviceHousehold;

		List<C501_Service_Household__c> cServices = IntakeServices.getServiceHistory(household1.Id);
		//System.assert(cServices.size() == 1);	
	}	
    
}