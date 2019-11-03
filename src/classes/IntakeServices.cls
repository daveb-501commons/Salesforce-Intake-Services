public with sharing class IntakeServices {

    private static String Unknown = 'Unknown';
    // Trigger NPSP Logic to update name based on NPSP Settings
    private static String NPSPTriggerNameUpdate = 'REPLACE';

    public class IntakeServicesException extends Exception {}

    private map<String, String> params = ApexPages.CurrentPage().getParameters();

    public Class ClientCheckin {
        public Id clientId { get; private set; }
        public Id clientContactId { get; private set; }
        public String name { get; private set; }
        public String notes { get; private set; }
        public Decimal pointsRemaining { get; private set; }
        public String visitType { get; private set; }
        public String serviceLocation { get; private set; }
        public String boxSize { get; private set; }
        public DateTime checkInTime { get; private set; }
        public Boolean checkinNotToday { get; private set; }
        public DateTime checkInTimeWithStaff { get; private set; }
        public Boolean withStaff { get; private set; }
    }

    //
    //  Location for optimzation - same Fx in  https://github.com/501Commons/Salesforce-Service-Management/src/C501_TriggerHelper.cls
    //      Optimization is to have a single function return the query and then walk through the fields in a loop and set the values without explicitly referencing the api name - refer to MMA project
    //
    private static void CreateServiceContacts(C501_Service_Household__c serviceHousehold, Id householdId) {

        System.debug(LoggingLevel.DEBUG, '***** IntakeServices::CreateServiceContacts');

        List<Contact> householdContacts = [SELECT 
					Account.Id, Account.npe01__One2OneContact__c,
					AccountId, Id, Name,
					FirstName, LastName, MiddleName, C501_FirstName_Initial__c,
					Birthdate, C501_IS_Birthdate_Searchable__c, C501_IS_Other_Names_Searchable__c,
					C501_Partial_Social_Security_Id__c, C501_Order__c,
					C501_Age__c, C501_Military_Status__c, C501_Disabling_Condition_Special_Needs__c,
					C501_Developmental_Disability__c, C501_Medicaid__c, C501_Medicare__c,
					C501_Education_Level__c, C501_Health_Insurance__c, C501_Race__c, C501_Ethnicity__c, Gender__c,
					C501_Preferred_Language__c, C501_Additional_Languages__c,
					C501_Work_Status__c, C501_Case_Worker__c, C501_Is_In_Household__c
				FROM Contact
				WHERE AccountId = :householdId];

        List<C501_Service_Contact__c> insertServiceContacts = new List<C501_Service_Contact__c>();
        for (Contact contactRecord :householdContacts) {

            C501_Service_Contact__c sc = new C501_Service_Contact__c(
                Name = serviceHousehold.Name,
                C501_Service_Household_Id__c = serviceHousehold.Id,
                C501_Service_Id__c = serviceHousehold.C501_Service_Id__c,
                C501_Contact__c = contactRecord.Id,
                C501_Contact_Id__c = String.valueOf(contactRecord.Id) + String.valueOf(serviceHousehold.Id),
                C501_Trigger_Ignore_Change__c = true
            );
            CopyFieldsContact2ServiceContact(contactRecord, sc);

            insertServiceContacts.add(sc);
        }

        if (!insertServiceContacts.isEmpty()) {
            insert insertServiceContacts;
        }
    }


    //
    //  CheckServiceHouseholdRecords - Debug code used to fix legacy Information & Referral to a new structure with Service Contacts
    //
    private static void CheckServiceHouseholdRecords() {
/*
        System.debug(LoggingLevel.DEBUG, '***** IntakeServices::CheckServiceHouseholdRecords');

        List<C501_Service_Household__c> serviceHouseholds = [SELECT Id, C501_Program__c, Name, C501_Service_Id__c, C501_Household__c FROM C501_Service_Household__c WHERE C501_Program__c = 'Information & Referral' AND CreatedDate = THIS_YEAR];
        List<String> serviceHouseholdIds = new List<String>();
        for (C501_Service_Household__c serviceHousehold :serviceHouseholds) {
            serviceHouseholdIds.add(serviceHousehold.Id);
        }

        List<C501_Service_Contact__c> serviceContacts = [Select Id, C501_Service_Household_Id__c From C501_Service_Contact__c Where C501_Service_Household_Id__c in :serviceHouseholdIds];
        Set<String> serviceHouseholdWithContact = new Set<String>();
        for (C501_Service_Contact__c serviceContact :serviceContacts) {
            serviceHouseholdWithContact.add(serviceContact.C501_Service_Household_Id__c);
        }

        for (C501_Service_Household__c serviceHousehold :serviceHouseholds) {

            if (serviceHouseholdWithContact.contains(serviceHousehold.Id)) {
                System.debug(LoggingLevel.DEBUG, '***** Service Household Has a Contact Name: ' + serviceHousehold.Name + ' Program: ' + serviceHousehold.C501_Program__c);
                continue;
            }
            
            System.debug(LoggingLevel.DEBUG, '***** Service Household Has No Contacts: ' + serviceHousehold.Name + ' Program: ' + serviceHousehold.C501_Program__c);
            CreateServiceContacts(serviceHousehold, serviceHousehold.C501_Household__c);
        }
*/
    }

    //
    //  Location for optimzation - same Fx in  https://github.com/501Commons/Salesforce-Service-Management/src/C501_TriggerHelper.cls
    //      Optimization is to have a single function return the query and then walk through the fields in a loop and set the values without explicitly referencing the api name - refer to MMA project
    //
	private static void CopyFieldsContact2ServiceContact(Contact c, C501_Service_Contact__c sc) {

        System.debug(LoggingLevel.DEBUG, '***** IntakeServices::CopyFieldsContact2ServiceContact');

        sc.C501_First_Name__c = c.FirstName;
        sc.C501_FirstName_Initial__c = c.C501_FirstName_Initial__c;
        sc.C501_Last_Name__c = c.LastName;
        sc.C501_Middle_Name__c = c.MiddleName;
        sc.C501_Birthdate__c = c.Birthdate;
        sc.C501_Is_In_Household__c = c.C501_Is_In_Household__c;
        sc.C501_Partial_Social_Security_Id__c = c.C501_Partial_Social_Security_Id__c;
        sc.C501_Order__c = c.C501_Order__c;
        sc.C501_Age__c = c.C501_Age__c;
        sc.C501_Military_Status__c = c.C501_Military_Status__c;
        sc.C501_Disabling_Condition_Special_Needs__c = c.C501_Disabling_Condition_Special_Needs__c;
        sc.C501_Education_Level__c = c.C501_Education_Level__c;
        sc.C501_Developmental_Disability__c = c.C501_Developmental_Disability__c;
        sc.C501_Medicare__c = c.C501_Medicare__c;
        sc.C501_Medicaid__c = c.C501_Medicaid__c;
        sc.C501_Health_Insurance__c = c.C501_Health_Insurance__c;
        sc.C501_Race__c = c.C501_Race__c;
        sc.C501_Ethnicity__c = c.C501_Ethnicity__c;
        sc.C501_Gender__c = c.Gender__c;
        sc.C501_Preferred_Language__c = c.C501_Preferred_Language__c;
        sc.C501_Additional_Languages__c = c.C501_Additional_Languages__c;
        sc.C501_Work_Status__c = c.C501_Work_Status__c;
        sc.C501_Case_Worker__c = c.C501_Case_Worker__c;
	}

    //
    //  Location for optimzation - same Fx in  https://github.com/501Commons/Salesforce-Service-Management/src/C501_TriggerHelper.cls
    //      Optimization is to have a single function return the query and then walk through the fields in a loop and set the values without explicitly referencing the api name - refer to MMA project
    //
	private static void CopyFieldsAccount2ServiceAccount(Id hhId, C501_Service_Household__c sh) {

        System.debug(LoggingLevel.DEBUG, '***** IntakeServices::CopyFieldsAccount2ServiceAccount');

		List<Account> households =
				[SELECT Id, Name, 
					BillingStreet, BillingCity, BillingState, BillingPostalCode,
					ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode,
					C501_SNAP__c, C501_Other_Income__c, C501_Earned_Income__c, C501_Self_Employed__c, C501_Unemployment_Insurance__c, C501_Child_Support__c,
					C501_Pension__c, C501_Retirement_Income_Social_Security__c, C501_Supplemental_Security_Income__c, C501_Social_Security_Disability_Income__c,
					C501_TANF__c, C501_WIC__c, C501_Household_Income_Sources__c, C501_Annual_Income__c, C501_Housing__c,
					C501_VA_Service_Connected_Disability__c, C501_Worker_s_Compensation__c,
					C501_Household_Size__c, C501_Household_Type__c, Phone, npo02__HouseholdPhone__c,
					C501_Years_At_Current_Address__c, C501_Current_Address_Move_In_Year__c, C501_Case_Worker__c
				FROM Account
                WHERE id = :hhId];

        if (households.isEmpty()) {
            return;
        }

        sh.C501_BillingStreet__c = households[0].BillingStreet;
        sh.C501_BillingCity__c = households[0].BillingCity;
        sh.C501_BillingState__c = households[0].BillingState;
        sh.C501_BillingPostalCode__c = households[0].BillingPostalCode;
        sh.C501_ShippingStreet__c = households[0].ShippingStreet;
        sh.C501_ShippingCity__c = households[0].ShippingCity;
        sh.C501_ShippingState__c = households[0].ShippingState;
        sh.C501_ShippingPostalCode__c = households[0].ShippingPostalCode;
        sh.C501_Phone__c = households[0].Phone;
        sh.C501_Other_Phone__c = households[0].npo02__HouseholdPhone__c;
        sh.C501_SNAP__c = households[0].C501_SNAP__c;
        sh.C501_Other_Income__c = households[0].C501_Other_Income__c;
        sh.C501_Earned_Income__c = households[0].C501_Earned_Income__c;
        sh.C501_Self_Employed__c = households[0].C501_Self_Employed__c;
        sh.C501_Unemployment_Insurance__c = households[0].C501_Unemployment_Insurance__c;
        sh.C501_Child_Support__c = households[0].C501_Child_Support__c;
        sh.C501_Pension__c = households[0].C501_Pension__c;
        sh.C501_Retirement_Income_Social_Security__c = households[0].C501_Retirement_Income_Social_Security__c;
        sh.C501_Supplemental_Security_Income__c = households[0].C501_Supplemental_Security_Income__c;
        sh.C501_Social_Security_Disability_Income__c = households[0].C501_Social_Security_Disability_Income__c;
        sh.C501_TANF__c = households[0].C501_TANF__c;
        sh.C501_Household_Income_Sources__c = households[0].C501_Household_Income_Sources__c;
        sh.C501_Annual_Income__c = households[0].C501_Annual_Income__c;
        sh.C501_Housing__c = households[0].C501_Housing__c;
        sh.C501_VA_Service_Connected_Disability__c = households[0].C501_VA_Service_Connected_Disability__c;
        sh.C501_Worker_s_Compensation__c = households[0].C501_Worker_s_Compensation__c;
        sh.C501_Household_Size__c = households[0].C501_Household_Size__c;
        sh.C501_Household_Type__c = households[0].C501_Household_Type__c;
        sh.C501_Years_At_Current_Address__c = households[0].C501_Years_At_Current_Address__c;
        sh.C501_Current_Address_Move_In_Year__c = households[0].C501_Current_Address_Move_In_Year__c;
        sh.C501_Case_Worker__c = households[0].C501_Case_Worker__c;
	}

    public static list<ClientCheckin> getCheckedInListCollection(boolean with_staff, String serviceLocation) {

        list<ClientCheckin> chkList = new list<ClientCheckin>();
        //    delete fbc;
        //}

        for (Intake_Services_Checkin__c fbc : Intake_Services_Checkin__c.getAll().values()) {

            if (fbc.C501_IS_Service_Location__c != serviceLocation) {
                continue;
            }

            if (fbc.C501_With_Staff__c != with_staff) {
                continue;
            }

System.debug(fbc);

            ClientCheckin cc = new ClientCheckin();
            cc.clientId = (fbc.C501_IS_Household__c != null) ? fbc.C501_IS_Household__c : fbc.name;
            cc.clientContactId = fbc.C501_IS_Visitor__c;
            cc.name = IntakeServices.getContactName(fbc.C501_IS_Visitor__c);
            cc.notes = !String.isBlank(fbc.C501_IS_Notes__c) && fbc.C501_IS_Notes__c.length() > 64 ? fbc.C501_IS_Notes__c.left(64) + '...' : fbc.C501_IS_Notes__c;
            cc.pointsRemaining = fbc.Points_Remaining__c;
            cc.visitType = fbc.C501_IS_Visit_Type__c;
            cc.serviceLocation = fbc.C501_IS_Service_Location__c;
            cc.boxSize = fbc.Box_Size__c;
            cc.checkInTime = fbc.Check_In_Time__c;
            cc.checkInTimeWithStaff = fbc.Check_In_Time_With_Staff__c;
            cc.checkinNotToday = (cc.checkInTime != null && cc.checkInTime.date() != system.today());
            cc.withStaff = fbc.C501_With_Staff__c;

            chkList.add( cc );
        }

        // Sort List
        if (with_staff) {
            for (Integer i =0; i < chkList.size(); i++) {
                for (Integer j = i; j > 0; j--) {
                    if (chkList[j-1].checkInTimeWithStaff > chkList[j].checkInTimeWithStaff){
                        ClientCheckin temp = chkList[j];
                        chkList[j] = chkList[j-1];
                        chkList[j-1] = temp;
                    }
                }
            }
        } else {
            for (Integer i =0; i < chkList.size(); i++) {
                for (Integer j = i; j > 0; j--) {
                    if (chkList[j-1].checkInTime > chkList[j].checkInTime){
                        ClientCheckin temp = chkList[j];
                        chkList[j] = chkList[j-1];
                        chkList[j-1] = temp;
                    }
                }
            }
        }

        return chkList;
    }

    @RemoteAction
    public static list<ClientCheckin> getCheckedInList(String serviceLocation) {
        return getCheckedInListCollection(false, serviceLocation);
    }

    @RemoteAction
    public static list<ClientCheckin> getCheckedInListWithStaff(String serviceLocation) {
        return getCheckedInListCollection(true, serviceLocation);
    }

    @RemoteAction
    public static Account getHouseholdDetail( Id hhid ) {
        Account hh =
            [select Id, Name, CreatedDate, LastModifiedDate, C501_IS_First_Visit__c, C501_IS_Most_Recent_Visit__c,
                C501_IS_Total_Visits__c, C501_IS_Homeless__c, C501_IS_Out_Of_Area__c, BillingStreet, BillingCity, BillingState, BillingPostalCode,
                C501_IS_Inactive__c, C501_IS_Notes__c, C501_IS_Tag_Notes__c, C501_IS_Source__c, C501_IS_External_Id__c, C501_IS_Adults__c,
                C501_IS_Children__c, C501_IS_Infants__c, C501_IS_Seniors__c, C501_IS_Tags__c,
                C501_IS_Staff_Notes__c, Phone, C501_IS_Proof_of_Address__c, C501_IS_Proof_of_Address_Date__c,
                (select Id, Name, FirstName, LastName, C501_IS_Age_Group__c, C501_IS_Age__c, Birthdate, C501_IS_Proof_of_Infant__c, C501_IS_Gender__c, C501_IS_Id_Number__c,
                C501_Ethnicity__c, C501_Race__c, C501_Military_Status__c, C501_Is_In_Household__c, Email, Phone
                    from Contacts),
                (select C501_IS_Points_Used__c, C501_IS_Commodity_Usage_JSON__c from Visits__r where C501_IS_Visit_Date__c = THIS_MONTH)
                from Account where id = :hhid];

        if (IntakeServicesSettings.general.Track_Points__c)
            hh.C501_IS_Monthly_Points_Available__c = getMonthlyPoints( hh );

        // Get any Checkin Commodities Pending
        Intake_Services_Checkin__c fbc = null;
        List<Intake_Services_Checkin__c> intakes = [Select Id, C501_IS_Commodity_Usage_JSON__c, C501_IS_Notes__c  From Intake_Services_Checkin__c where (Name = :hhid or C501_IS_Household__c = :hhid)];
        if (!intakes.isEmpty()) {
            fbc = intakes[0];
        }
        if (fbc != null) {
            hh.C501_IS_Pending_Commodity_Usage_JSON__c = fbc.C501_IS_Commodity_Usage_JSON__c; 
            hh.C501_IS_Pending_Notes__c = fbc.C501_IS_Notes__c; 
        }

        /*
        // if last visit date is not this month, recalculate points
        if (IntakeServicesSettings.general.Track_Points__c) {
            hh.C501_IS_Monthly_Points_Available__c = getMonthlyPoints( hh );
            if (hh.C501_IS_Most_Recent_Visit__c == null) {
                hh.C501_IS_Current_Points_Used__c = 0;
            } else if (hh.C501_IS_Current_Points_Used__c == null || hh.C501_IS_Most_Recent_Visit__c.year() != system.today().year() || hh.C501_IS_Most_Recent_Visit__c.month() != system.today().month()) {
                AggregateResult ar = [SELECT SUM(C501_IS_Points_Used__c) TotalPoints FROM Client_Visit__c WHERE Id = : hh.id AND C501_IS_Visit_Date__c = THIS_MONTH];
                Decimal pu = (Decimal)(ar.get('TotalPoints'));
                hh.C501_IS_Current_Points_Used__c = (pu == null) ? 0 : pu;
            }
        }
        */
        return hh;
    }

    @RemoteAction
    public static list<Client_Visit__c> getVisitHistory( Id hhid ) {
        return
            [select Id, C501_IS_Visit_Date__c, C501_IS_Box_Type__c, C501_IS_Points_Used__c, C501_IS_Checkout_Weight__c, C501_IS_Notes__c, C501_IS_Visitor__r.Name
                from Client_Visit__c
                where C501_IS_Household__c = :hhid
                order by C501_IS_Visit_Date__c DESC limit 20];
    }

    @RemoteAction
    public static list<C501_Service_Household__c> getServiceHistory( Id hhid ) {

        Set<Id> serviceHouseholdIds = new Set<Id>();
        for (C501_Service_Contact__c serviceContact :[
            SELECT C501_Service_Household_Id__r.Id
            FROM C501_Service_Contact__c
            WHERE C501_Contact__r.AccountId = :hhid]) {

            serviceHouseholdIds.add(serviceContact.C501_Service_Household_Id__r.Id);
        }

        for (C501_Service_Household__c serviceHousehold :[
            SELECT Id
            FROM C501_Service_Household__c
            WHERE C501_Household__c = :hhid]) {

            serviceHouseholdIds.add(serviceHousehold.Id);
        }

        return
            [select Id, Name, C501_Case_Worker__c, C501_Start_Date__c, C501_End_Date__c, C501_IsActive__c
                from C501_Service_Household__c
                where Id in :serviceHouseholdIds
                order by C501_Start_Date__c DESC limit 20];
    }

    @RemoteAction
    public static Account saveHousehold( Account hh ) {

        hh.Name = IntakeServices.NPSPTriggerNameUpdate;

        if (hh.Id == null)
            insert hh;
        else
            update hh;

        hh = getHouseholdDetail( hh.Id );
        return hh;
    }

    @RemoteAction
    public static Account saveHouseholdAndMembers( Account hh, list<Contact> clients) {

        hh.Name = IntakeServices.NPSPTriggerNameUpdate;

        hh.C501_IS_Monthly_Points_Available__c = getMonthlyPoints( hh );  // is this by trigger?  how about the name?
        if (hh.Id == null)
            insert hh;
        else
            update hh;

        return saveHouseholdMembers( hh.id, clients );
    }

    @RemoteAction
    public static Account saveHouseholdMembers( Id hhId, list<Contact> clients ) {

        if (clients != null) {
            list<Contact> clientsToInsert = new list<Contact>();
            list<Contact> clientsToUpdate = new list<Contact>();
            set<Id> clientIds = new set<Id>();

            for (Contact client : clients) {
                if (client.LastName != null) {

                    client.AccountId = hhId;

                    // ToDo - Integrate with NPSP Address Management 
                    Account hh = getHouseholdDetail( hhId );
                    client.MailingStreet = hh.BillingStreet;
                    client.MailingCity = hh.BillingCity;
                    client.MailingState = hh.BillingState;
                    client.MailingPostalCode = hh.BillingPostalCode;

                    if (client.Id == null) {
                        clientsToInsert.add(client.clone());
                    } else {
                        clientsToUpdate.add(client);
                        clientIds.add(client.Id);
                    }
                }
            }
            
            list<Contact> clientsToDelete = [select id from Contact where AccountId = : hhId
                and Id not in :clientIds];

            if (!clientsToDelete.isEmpty())
                delete clientsToDelete;
            if (!clientsToUpdate.isEmpty())
                update clientsToUpdate;
            if (!clientsToInsert.isEmpty())
                insert clientsToInsert;
        }

        return getHouseholdDetail( hhId );
    }

    static Decimal getMonthlyPoints( Account hh ) {
        Decimal pts = 0;
        if (hh != null) {
            if (IntakeServicesSettings.general.Monthly_Base_Points__c != null)
                pts += IntakeServicesSettings.general.Monthly_Base_Points__c;
            if (IntakeServicesSettings.general.Monthly_points_per_Adult__c != null && hh.C501_IS_Adults__c != null)
                pts += (IntakeServicesSettings.general.Monthly_points_per_Adult__c * hh.C501_IS_Adults__c);
            if (IntakeServicesSettings.general.Monthly_points_per_Adult__c != null && hh.C501_IS_Seniors__c != null)
                pts += (IntakeServicesSettings.general.Monthly_points_per_Adult__c * hh.C501_IS_Seniors__c);
            if (IntakeServicesSettings.general.Monthly_points_per_Child__c != null && hh.C501_IS_Children__c != null)
                pts += (IntakeServicesSettings.general.Monthly_points_per_Child__c * hh.C501_IS_Children__c);
            if (IntakeServicesSettings.general.Monthly_points_per_Child__c != null && hh.C501_IS_Infants__c != null)
                pts += (IntakeServicesSettings.general.Monthly_points_per_Child__c * hh.C501_IS_Infants__c);
        }
        return pts;
    }

    static String getContactName(Id contactid){
        
        if (contactId == null) {
            return IntakeServices.Unknown;
        }

		//Contact c = [select id, name from Contact where id =: contactid];
        list<Contact> c = [select Id, AccountId, Name from Contact where id =: contactid];
        if (!c.isEmpty()) {
            return c[0].Name;
        }

        return IntakeServices.Unknown;
    }


    @RemoteAction
    public static Account createNewHousehold( Account hhData, list<Contact> clientData ) {
        Account hh;

        // calculate points and commodity data and save

        return hh;
    }

    @RemoteAction
    public static void checkIn( Id hhid, Id contactid, Map<String, Integer> commodityUsage, String visitNotes, boolean withStaff, String visitType, String visitDate, List<String> services, List<String> referrals, String serviceLocation) {

        System.debug(LoggingLevel.DEBUG, '***** IntakeServices::checkIn');

        Account hh =
            [select id, Name, C501_IS_Adults__c, C501_IS_Seniors__c, C501_IS_Children__c, C501_IS_Infants__c,
                (select C501_IS_Points_Used__c from Visits__r where C501_IS_Visit_Date__c = THIS_MONTH)
                from Account where id = :hhid];

        Intake_Services_Checkin__c fbc = new Intake_Services_Checkin__c();
        List<Intake_Services_Checkin__c> intakes = [Select Id, C501_IS_Commodity_Usage_JSON__c, Points_Remaining__c from Intake_Services_Checkin__c where (Name = :hhid or C501_IS_Household__c = :hhid) and C501_IS_Service_Location__c = :serviceLocation];
        if (!intakes.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, '***** IntakeServices::checkIn - update checkin');
            fbc = intakes[0];

            fbc.Check_In_Time_With_Staff__c = system.now();
            fbc.C501_With_Staff__c = withStaff;

            update fbc;
        } else {
            System.debug(LoggingLevel.DEBUG, '***** IntakeServices::checkIn - insert checkin');

            fbc.name = hhid + serviceLocation;
            fbc.C501_IS_Household__c = hhid;
            fbc.Points_Remaining__c = getMonthlyPoints( hh );
            for (Client_Visit__c cv : hh.Visits__r)
                if (cv.C501_IS_Points_Used__c != null) fbc.Points_Remaining__c -= cv.C501_IS_Points_Used__c;

            Datetime currentDatetime = Datetime.now();
            Date currentDate = currentDatetime.date();
            Date visitDateIncoming = Date.parse(visitDate);
            Integer dayDifference = currentDate.daysBetween(visitDateIncoming);
            Datetime visitDatetime = currentDatetime.addDays(dayDifference);

            fbc.Check_In_Time__c = visitDatetime;
            fbc.C501_IS_Visitor__c = contactid;
            fbc.C501_IS_Visit_Type__c = visitType;
            fbc.C501_IS_Service_Location__c = serviceLocation;

            fbc.C501_IS_Notes__c = visitNotes;
System.debug('checkin - visitNotes: ' + visitNotes);
            fbc.C501_With_Staff__c = withStaff;

            if (commodityUsage != null && !commodityUsage.isEmpty()) {
                fbc.C501_IS_Commodity_Usage_JSON__c = JSON.serializePretty(commodityUsage);
            }

            insert fbc;
        }

        try {

            // Create new Service records for Commodities, Services, and Referrals
            //

            if (commodityUsage != null && !commodityUsage.isEmpty()) {
                for (String commodity : commodityUsage.keySet()) {

                    System.debug(LoggingLevel.DEBUG, '***** IntakeServices::checkIn - insert commodity: ' + commodity);

                    String cleanName = commodity
                        .replace('_FORWARDSLASH_', '/')
                        .replace('_', ' ');

                    C501_Service_Household__c sh = new C501_Service_Household__c(
                        Name = hh.Name + ' (' + cleanName + ')',
                        C501_Service_Id__c = 'Information & Referral' + cleanName + Datetime.now().format() + hh.id,
                        C501_Household__c = hh.id,
                        C501_Program__c = 'Information & Referral',
                        C501_Service__c = cleanName,
                        C501_Start_Date__c = Date.Today(),
                        C501_End_Date__c = Date.Today(),
                        C501_IsActive__c = false,
                        C501_Trigger_Ignore_Change__c = true,
                        C501_Location__c = serviceLocation
                    );

                    CopyFieldsAccount2ServiceAccount(hh.Id, sh);

                    insert sh;

                    // Create Service Contacts based on the current contacts in the household
                    CreateServiceContacts(sh, hhId);
                }
            }

            if (services != null && !services.isEmpty()) {
                for (String service : services) {

                    System.debug(LoggingLevel.DEBUG, '***** IntakeServices::checkIn - insert service: ' + service);

                    String cleanName = service
                        .replace('_FORWARDSLASH_', '/')
                        .replace('_', ' ');
                    C501_Service_Household__c sh = new C501_Service_Household__c(
                        Name = hh.Name + ' (' + cleanName + ')',
                        C501_Service_Id__c = 'Information & Referral' + cleanName + Datetime.now().format() + hh.id,
                        C501_Household__c = hh.id,
                        C501_Program__c = 'Information & Referral',
                        C501_Service__c = cleanName,
                        C501_Start_Date__c = Date.Today(),
                        C501_End_Date__c = Date.Today(),
                        C501_IsActive__c = false,
                        C501_Trigger_Ignore_Change__c = true,
                        C501_Location__c = serviceLocation
                    );

                    CopyFieldsAccount2ServiceAccount(hh.Id, sh);

                    insert sh;

                    // Create Service Contacts based on the current contacts in the household
                    CreateServiceContacts(sh, hhId);
                }
            }

            if (referrals != null && !referrals.isEmpty()) {
                for (String referral : referrals) {

                    System.debug(LoggingLevel.DEBUG, '***** IntakeServices::checkIn - insert referral: ' + referral);

                    String cleanName = referral
                        .replace('_FORWARDSLASH_', '/')
                        .replace('_', ' ');
                    C501_Service_Household__c sh = new C501_Service_Household__c(
                        Name = hh.Name + ' (' + cleanName + ')',
                        C501_Service_Id__c = 'Information & Referral' + cleanName + Datetime.now().format() + hh.id,
                        C501_Household__c = hh.id,
                        C501_Program__c = 'Information & Referral',
                        C501_Service__c = cleanName,
                        C501_Start_Date__c = Date.Today(),
                        C501_End_Date__c = Date.Today(),
                        C501_IsActive__c = false,
                        C501_Trigger_Ignore_Change__c = true,
                        C501_Location__c = serviceLocation
                    );

                    CopyFieldsAccount2ServiceAccount(hh.Id, sh);

                    insert sh;

                    // Create Service Contacts based on the current contacts in the household
                    CreateServiceContacts(sh, hhId);
                }
            }

            // Check to fix any Service Households that don't have any Service Contacts
            CheckServiceHouseholdRecords();

        } catch (Exception ex) {
            system.debug(ex.getMessage());
        }
    }

    @RemoteAction
    public static void cancelCheckIn( Id hhid ) {
        List<Intake_Services_Checkin__c> intakes = [Select Id From Intake_Services_Checkin__c where (Name = :hhid or C501_IS_Household__c = :hhid)];
        if (!intakes.isEmpty()) delete intakes;
    }

    @RemoteAction
    public static IntakeServicesStats getStats( String timeframe ) {

        IntakeServicesStats s = new IntakeServicesStats();
        s.queryStats(timeframe);
        return s;
    }

    @RemoteAction
    public static String getCustomLabel( String label ) {

        if (label == 'C501_IS_Box_Type__c')
            return System.Label.Intake_Services_Box_Type;

        return 'Undefined';
    }

// TODO: REFACTOR FOR CONSISTENCY????
    public Class ClientHousehold {
        public String id;
        public String contactid;
        public String value;
        public String name;
        public String addr;
        //public list<String> tags;
    }

    // queryHouseholds
    //  
    // query: User entered string in UI (e.g., name, address, partial address)  
    @RemoteAction
    public static list<ClientHousehold> queryHouseholds( String query){//, Boolean includeInactive ) {
        list<ClientHousehold> hhRet = new list<ClientHousehold>();

        query = query
            .replace('\\', '\\\\');

        // Id Number search: back part of the Id can frequently change so stripe off back half of query to try for match
        String halfquery = query;
        if (halfquery.length() >= 16) {
            query.left(query.length() / 2);
        }

        // Expand to return all Clients for a household
        List<List<SObject>> resultList =
//            [FIND :(query + '* OR ' + halfquery + '*') 
            [FIND :(query + '*') 
                RETURNING Contact( 
                    Name, C501_IS_Id_Number__c, MailingStreet,
                    Account.Name, Account.Id, Email,
                    C501_IS_Birthdate_Searchable__c, C501_IS_Other_Names_Searchable__c,
                    C501_Partial_Social_Security_Id__c, Phone
                WHERE Account.C501_IS_Inactive__c != true 
                ORDER BY Name)];

// TODO: should not need to translate here
        for (sObject obj : resultList[0]) {
            Contact rec = (Contact)obj;
            ClientHousehold chh = new ClientHousehold();
            chh.id = rec.Account.Id;
            chh.contactid = rec.Id;

            // name and addr are displayed in UI for selection
            chh.name = rec.Name;
            chh.addr = rec.MailingStreet;

            chh.value = 
                ((rec.C501_IS_Id_Number__c != null) ? (' (' + rec.C501_IS_Id_Number__c + ')') : '')
                + ((rec.MailingStreet != null) ? (' (' + rec.MailingStreet + ')') : '');

            hhRet.add( chh );
        }

        return hhRet;
    }

    // custom class allows us to return all settings in a single remote call
    public class AppSettings {
        public Intake_Services_Settings__c general { get; set; }
        public List<Intake_Services_Commodity__c> commodities { get; set; }
        public List<Intake_Services__c> services { get; set; }
        public List<Intake_Referrals__c> referrals { get; set; }
        public List<Intake_Services_Box_Settings__c> boxes { get; set; }
    }

    @RemoteAction
    public static AppSettings getAppSettings() {
        AppSettings s = new AppSettings();
        s.general = IntakeServicesSettings.general;
        s.commodities = IntakeServicesSettings.commodities;
        s.services = IntakeServicesSettings.services;
        s.referrals = IntakeServicesSettings.referrals;
        s.boxes = IntakeServicesSettings.boxes;
        return s;
    }

    @RemoteAction
    public static Id logVisit( Id hhId, Id contactId, String boxType, Decimal checkoutWeight, Integer pointsUsed, Map<String, Integer> commodityUsage, String visitType, String visitDate, String visitNotes, List<String> services, List<String> referrals, String serviceLocation, String createdBy) {

        System.debug(LoggingLevel.DEBUG, '*****IntakeServices::logVisit Start - services: ' + services + ' referrals: ' + referrals + ' serviceLocation: ' + serviceLocation + ' createdBy: ' + createdBy);

        // get the HH detail
        Account[] hhs =
            [select Id, Name, C501_IS_Adults__c, C501_IS_Children__c, C501_IS_Infants__c, C501_IS_Seniors__c, C501_IS_Homeless__c, C501_IS_Out_Of_Area__c, C501_IS_Inactive__c
                from Account where id = :hhid];

        if ( hhs.isEmpty() ) {
            throw new IntakeServicesException('Household not found.');
        }

        Account hh = hhs[0];

        // TODO: validate remaining points? non-negative and under limit (unless setting allows exception)

        // TODO: activate inactive client? or disallow visit?

        // Validate Contact references are still valid because between the checkin time and log visit the Contact could have been deleted
        list<Contact> c = [select id from Contact where id = :contactid];
        if (c.isEmpty()) {
            contactid = null;
        }

        Intake_Services_Checkin__c fbc = new Intake_Services_Checkin__c();
        List<Intake_Services_Checkin__c> intakes = [Select Id , C501_IS_Visitor__c, C501_IS_Visit_Type__c, Check_In_Time__c, C501_IS_Commodity_Usage_JSON__c from Intake_Services_Checkin__c where (Name = :hhid or C501_IS_Household__c = :hhid) and C501_IS_Service_Location__c = :serviceLocation];
        if (!intakes.isEmpty()) {
            fbc = intakes[0];
            c = [select id from Contact where id = :fbc.C501_IS_Visitor__c];
            if (!c.isEmpty()) {
                fbc.C501_IS_Visitor__c = null;
            }
        }

        Datetime currentDatetime = Datetime.now();
        Date currentDate = currentDatetime.date();
        Date visitDateIncoming = Date.parse(visitDate);
        Integer dayDifference = currentDate.daysBetween(visitDateIncoming);
        Datetime visitDatetime = currentDatetime.addDays(dayDifference);

        // log the visit
        Client_Visit__c cv = new Client_Visit__c(
            C501_IS_Household__c = hh.Id,
            C501_IS_Adults__c = hh.C501_IS_Adults__c,
            C501_IS_Seniors__c = hh.C501_IS_Seniors__c,
            C501_IS_Children__c = hh.C501_IS_Children__c,
            C501_IS_Infants__c = hh.C501_IS_Infants__c,
            C501_IS_Homeless__c = hh.C501_IS_Homeless__c,
            C501_IS_Out_Of_Area__c = hh.C501_IS_Out_Of_Area__c,
            C501_IS_Points_Used__c = pointsUsed,
            C501_IS_Checkout_Weight__c = checkoutWeight,
            C501_IS_Box_Type__c = boxType,
            C501_IS_Notes__c = visitNotes,
            C501_IS_Visit_Type__c = (fbc != null && fbc.C501_IS_Visit_Type__c != null && fbc.C501_IS_Visit_Type__c != '') ? fbc.C501_IS_Visit_Type__c : visitType,
            C501_IS_Service_Location__c = serviceLocation,
            C501_IS_Visit_Date__c = (fbc != null && fbc.Check_In_Time__c != null) ? fbc.Check_In_Time__c : visitDatetime,
            C501_IS_Visitor__c = (fbc != null && fbc.C501_IS_Visitor__c != null) ? fbc.C501_IS_Visitor__c : contactid
        );

        if (commodityUsage != null && !commodityUsage.isEmpty())
            cv.C501_IS_Commodity_Usage_JSON__c = JSON.serializePretty(commodityUsage);

        try {
            insert cv;

            // TODO: recalc and save the remaining points on household
            if (pointsUsed != null && pointsUsed > 0) {}

            // remove the client from checkin list
            if (fbc != null) delete fbc;

        } catch (Exception ex) {
            system.debug(ex.getMessage());
        }

        try {
            // Create new Service records for Commodities, Services, and Referrals
            //

            if (commodityUsage != null && !commodityUsage.isEmpty()) {
                for (String commodity : commodityUsage.keySet()) {

                    String cleanName = commodity
                        .replace('_FORWARDSLASH_', '/')
                        .replace('_', ' ');
                    C501_Service_Household__c sh = new C501_Service_Household__c(
                        Name = hh.Name + ' (' + cleanName + ')',
                        C501_Service_Id__c = 'Information & Referral' + cleanName + Datetime.now().format() + hh.id,
                        C501_Household__c = hh.id,
                        C501_Program__c = 'Information & Referral',
                        C501_Service__c = cleanName,
                        C501_Start_Date__c = Date.parse(visitDate),
                        C501_End_Date__c = Date.parse(visitDate),
                        C501_IsActive__c = false,
                        C501_Trigger_Ignore_Change__c = true,
                        C501_Location__c = serviceLocation,
                        C501_Created_By__c = createdBy
                    );

                    CopyFieldsAccount2ServiceAccount(hh.Id, sh);

                    insert sh;

                    // Create Service Contacts based on the current contacts in the household
                    CreateServiceContacts(sh, hhId);
                }
            }

            System.debug(LoggingLevel.DEBUG, '*****IntakeServices::logVisit services: ' + services);

            if (services != null && !services.isEmpty()) {
                for (String service : services) {

                    String cleanName = service
                        .replace('_FORWARDSLASH_', '/')
                        .replace('_', ' ');
                    C501_Service_Household__c sh = new C501_Service_Household__c(
                        Name = hh.Name + ' (' + cleanName + ')',
                        C501_Service_Id__c = 'Information & Referral' + cleanName + Datetime.now().format() + hh.id,
                        C501_Household__c = hh.id,
                        C501_Program__c = 'Information & Referral',
                        C501_Service__c = cleanName,
                        C501_Start_Date__c = Date.parse(visitDate),
                        C501_End_Date__c = Date.parse(visitDate),
                        C501_IsActive__c = false,
                        C501_Trigger_Ignore_Change__c = true,
                        C501_Location__c = serviceLocation,
                        C501_Created_By__c = createdBy
                    );

                    CopyFieldsAccount2ServiceAccount(hh.Id, sh);

                    insert sh;

                    // Create Service Contacts based on the current contacts in the household
                    CreateServiceContacts(sh, hhId);
                }
            }

            System.debug(LoggingLevel.DEBUG, '*****IntakeServices::logVisit referrals: ' + referrals);

            if (referrals != null && !referrals.isEmpty()) {
                for (String referral : referrals) {

                    String cleanName = referral
                        .replace('_FORWARDSLASH_', '/')
                        .replace('_', ' ');
                    C501_Service_Household__c sh = new C501_Service_Household__c(
                        Name = hh.Name + ' (' + cleanName + ')',
                        C501_Service_Id__c = 'Information & Referral' + cleanName + Datetime.now().format() + hh.id,
                        C501_Household__c = hh.id,
                        C501_Program__c = 'Information & Referral',
                        C501_Service__c = cleanName,
                        C501_Start_Date__c = Date.parse(visitDate),
                        C501_End_Date__c = Date.parse(visitDate),
                        C501_IsActive__c = false,
                        C501_Trigger_Ignore_Change__c = true,
                        C501_Location__c = serviceLocation,
                        C501_Created_By__c = createdBy
                    );

                    CopyFieldsAccount2ServiceAccount(hh.Id, sh);

                    insert sh;

                    // Create Service Contacts based on the current contacts in the household
                    CreateServiceContacts(sh, hhId);
                }
            }

            // Check to fix any Service Households that don't have any Service Contacts
            CheckServiceHouseholdRecords();

        } catch (Exception ex) {
            system.debug(ex.getMessage());
        }

        return cv.id;
    }
}