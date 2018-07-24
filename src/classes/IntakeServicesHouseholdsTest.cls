@isTest
private class IntakeServicesHouseholdsTest {
    
    // NPSP Settings - has options under Households for Contact Overrun Count, Household Naming Conventions, and Bulk jobs for applying any changes so don't need to validate functionality built by NPSP

    // Test when there is only 1 child
    @isTest static void testSingleChild() {
        Account household = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Main Street',
            BillingCity = 'Seattle',
            BillingState = 'WA',
            BillingPostalCode = '98103'
        );
        insert household;

        List<Contact> clients = new List<Contact>();
        clients.add(createClient(household.Id, 'Amber', 'Smith', 12));
        insert clients;

        household = [ SELECT C501_IS_Infants__c, C501_IS_Children__c, C501_IS_Adults__c, C501_IS_Seniors__c FROM Account WHERE Id = :household.Id ];
        System.assertEquals(0, household.C501_IS_Infants__c, 'There are no infant clients');
        System.assertEquals(1, household.C501_IS_Children__c, 'There is 1 child client');
        System.assertEquals(0, household.C501_IS_Adults__c, 'There are no adult clients');
        System.assertEquals(0, household.C501_IS_Seniors__c, 'There are no senior clients');
    }

    // Test when there is only 1 adult
    @isTest static void testSingleAdult() {
        Account household = new Account(
            Name = 'Test Account'
        );
        insert household;

        List<Contact> clients = new List<Contact>();
        clients.add(createClient(household.Id, 'Amber', 'Smith', 57));
        insert clients;

        household = [ SELECT C501_IS_Infants__c, C501_IS_Children__c, C501_IS_Adults__c, C501_IS_Seniors__c FROM Account WHERE Id = :household.Id ];
        System.assertEquals(0, household.C501_IS_Infants__c, 'There are no infant clients');
        System.assertEquals(0, household.C501_IS_Children__c, 'There are no child clients');
        System.assertEquals(1, household.C501_IS_Adults__c, 'There is 1 adult client');
        System.assertEquals(0, household.C501_IS_Seniors__c, 'There are no senior clients');
    }

    // Test when there are 2 adults
    @isTest static void testTwoAdults() {
        Account household = new Account(
            Name = 'Test Account'
        );
        insert household;

        List<Contact> clients = new List<Contact>();
        clients.add(createClient(household.Id, 'Amber', 'Smith', 57));
        clients.add(createClient(household.Id, 'Joe', 'Smith', 55));
        insert clients;

        household = [ SELECT C501_IS_Infants__c, C501_IS_Children__c, C501_IS_Adults__c, C501_IS_Seniors__c FROM Account WHERE Id = :household.Id ];
        System.assertEquals(0, household.C501_IS_Infants__c, 'There are no infant clients');
        System.assertEquals(0, household.C501_IS_Children__c, 'There are no child clients');
        System.assertEquals(2, household.C501_IS_Adults__c, 'There are 2 adult clients');
        System.assertEquals(0, household.C501_IS_Seniors__c, 'There are no senior clients');
    }
    
    // Test all age categories
    @isTest static void testSeveralLastNames() {
        Account household = new Account(
            Name = 'Test Account'
        );
        insert household;

        List<Contact> clients = new List<Contact>();
        clients.add(createClient(household.Id, 'Joe', 'Burns', 88));
        clients.add(createClient(household.Id, 'Patty', 'Freeman', 8));
        clients.add(createClient(household.Id, 'Amber', 'Smith', 1));
        clients.add(createClient(household.Id, 'David', 'Gonzalez', 55));
        insert clients;

        household = [ SELECT C501_IS_Infants__c, C501_IS_Children__c, C501_IS_Adults__c, C501_IS_Seniors__c FROM Account WHERE Id = :household.Id ];
        System.assertEquals(1, household.C501_IS_Infants__c, 'There is 1 infant client');
        System.assertEquals(1, household.C501_IS_Children__c, 'There is 1 child client');
        System.assertEquals(1, household.C501_IS_Adults__c, 'There is 1 adult client');
        System.assertEquals(1, household.C501_IS_Seniors__c, 'There is 1 senior client');
    }
       
    private static Contact createClient(Id householdId, String firstName, String lastName, Integer age) {
        Contact client = new Contact( 
            AccountId = householdId, 
            FirstName = firstName,
            LastName = lastName, 
            Birthdate = System.today().addyears(-age)
        );
        return client;
    }
    
}