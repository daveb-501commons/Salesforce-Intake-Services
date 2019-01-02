@isTest
public with sharing class IntakeServicesTriggerTest {

    // NPSP Settings - has options under Households for Contact Overrun Count, Household Naming Conventions, and Bulk jobs for applying any changes so don't need to validate functionality built by NPSP

	@isTest
	private static void testClientTrigger() {
		Account hh = new Account(
            Name = 'Test Account'
		);
		insert hh;

		Contact c = new Contact( AccountId = hh.id, LastName = 'Test', Birthdate = system.today().addyears(-50) );
		insert c;

		Contact c1 = [select id, C501_IS_Age__c from Contact where id =: c.id];
		System.assertEquals(50, c1.C501_IS_Age__c ); 
		c.Birthdate = system.today().addyears(-45);
		update c;

		Contact c2 = [select id, C501_IS_Age__c from Contact where id =: c.id];
		System.assertEquals(45, c2.C501_IS_Age__c );
		Contact c3 = new Contact(  AccountId = hh.id, LastName = 'Test', C501_IS_Age__c = 40 );
		insert c3;

		Contact c4 = [select id, C501_IS_Age__c, Account.Name from Contact where id =: c3.id];
		System.assertEquals(40, c4.C501_IS_Age__c );

		Contact c5 = new Contact(  AccountId = hh.id, LastName = 'Test', C501_IS_Age__c = 5 );
		Contact c6 = new Contact(  AccountId = hh.id, LastName = 'Testy' );
		insert new list<Contact>{ c5, c6 };

		Contact c7 = [select id, C501_IS_Age__c, Account.C501_IS_Adults__c, Account.C501_IS_Children__c
							from Contact where id =: c6.id];
		System.assertEquals(3, c7.Account.C501_IS_Adults__c );
		System.assertEquals(1, c7.Account.C501_IS_Children__c );

		delete new list<Contact>{ c4, c5 };

		Contact c8 = [select id, C501_IS_Age__c, Account.C501_IS_Adults__c, Account.C501_IS_Children__c 
							from Contact where id =: c1.id];
		System.assertEquals(2, c8.Account.C501_IS_Adults__c );
		System.assertEquals(0, c8.Account.C501_IS_Children__c );
	}

	@isTest static void testChangeProofOfAddress() {
		Account household = new Account(
			Name = 'Test Account',
			BillingStreet = '123 Main Street',
            BillingCity = 'Seattle',
            BillingState = 'WA',
            BillingPostalCode = '98103',
            C501_IS_Proof_of_Address__c = 'Utility bill',
            C501_IS_Proof_of_Address_Date__c = System.today().addYears(-2)
		);
        insert household;

        household.C501_IS_Proof_of_Address__c = 'Staff verified - JS';
        update household;

        household = [ SELECT C501_IS_Proof_of_Address_Date__c FROM Account WHERE Id = :household.Id ];

        System.assertEquals(System.today(), household.C501_IS_Proof_of_Address_Date__c, 'Proof of Address date should update to current date');
	}

	@isTest static void testupdateContactAge() {
		Account household = new Account(
            Name = 'Test Account'
		);
        insert household;

        Contact c1 = new Contact(
        	AccountId = household.Id, 
        	LastName = 'Smith', 
        	C501_IS_Age__c = 55
        ); 
        insert c1;

        c1.C501_IS_Age__c = 55;
        c1.C501_IS_Age_Entry_Date__c = System.today().addYears(-2);
        update c1;

        c1 = [ SELECT C501_IS_Age__c, C501_IS_Age_Entry_Date__c FROM Contact WHERE Id = :c1.Id ];
        System.assertEquals(57, c1.C501_IS_Age__c, 'If age was 55 and was entered 2 years ago, age should be recalculated to 57');

	}

	@isTest
	private static void testVisitTrigger() {

		Account hh = new Account(
            Name = 'Test Account'
		);
		insert hh;

		Client_Visit__c cv = new Client_Visit__c(C501_IS_Household__c = hh.id, C501_IS_Visit_Date__c = System.today());
		insert cv;

		cv = [ SELECT C501_IS_First_Visit_This_Year__c FROM Client_Visit__c WHERE Id = :cv.Id ];
		System.assertEquals(true, cv.C501_IS_First_Visit_This_Year__c);

		Client_Visit__c cv2 = new Client_Visit__c(C501_IS_Household__c = hh.id, C501_IS_Visit_Date__c = System.today());
		insert cv2;

		cv = [ SELECT C501_IS_First_Visit_This_Year__c FROM Client_Visit__c WHERE Id = :cv.Id ];
		System.assertEquals(true, cv.C501_IS_First_Visit_This_Year__c);

		cv2 = [ SELECT C501_IS_First_Visit_This_Year__c FROM Client_Visit__c WHERE Id = :cv2.Id ];
		System.assertEquals(false, cv2.C501_IS_First_Visit_This_Year__c);
	}

	@isTest
	private static void testVisitTriggerNoDates() {

		Account hh = new Account(
            Name = 'Test Account'
		);
		insert hh;

		Client_Visit__c cv = new Client_Visit__c(C501_IS_Household__c = hh.id);
		insert cv;

		cv = [ SELECT C501_IS_First_Visit_This_Year__c FROM Client_Visit__c WHERE Id = :cv.Id ];
		System.assertEquals(true, cv.C501_IS_First_Visit_This_Year__c);

		Client_Visit__c cv2 = new Client_Visit__c(C501_IS_Household__c = hh.id);
		insert cv2;

		cv = [ SELECT C501_IS_First_Visit_This_Year__c FROM Client_Visit__c WHERE Id = :cv.Id ];
		cv2 = [ SELECT C501_IS_First_Visit_This_Year__c FROM Client_Visit__c WHERE Id = :cv2.Id ];
		System.assertEquals(true, cv.C501_IS_First_Visit_This_Year__c);
		System.assertEquals(false, cv2.C501_IS_First_Visit_This_Year__c);
	}
}