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
        public Decimal pointsRemaining { get; private set; }
        public String visitType { get; private set; }
        public String boxSize { get; private set; }
        public DateTime checkInTime { get; private set; }
        public Boolean checkinNotToday { get; private set; }
        public DateTime checkInTimeWithStaff { get; private set; }
        public Boolean withStaff { get; private set; }
    }

    public static list<ClientCheckin> getCheckedInListCollection(boolean with_staff) {

        list<ClientCheckin> chkList = new list<ClientCheckin>();
        //    delete fbc;
        //}

        for (Intake_Services_Checkin__c fbc : Intake_Services_Checkin__c.getAll().values()) {

            if (fbc.C501_With_Staff__c != with_staff) {
                continue;
            }

            ClientCheckin cc = new ClientCheckin();
            cc.clientId = fbc.name;
            cc.clientContactId = fbc.C501_IS_Visitor__c;
            cc.name = IntakeServices.getContactName(fbc.C501_IS_Visitor__c);
            cc.pointsRemaining = fbc.Points_Remaining__c;
            cc.visitType = fbc.C501_IS_Visit_Type__c;
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
    public static list<ClientCheckin> getCheckedInList() {
        return getCheckedInListCollection(false);
    }

    @RemoteAction
    public static list<ClientCheckin> getCheckedInListWithStaff() {
        return getCheckedInListCollection(true);
    }

    @RemoteAction
    public static Account getHouseholdDetail( Id hhid ) {
        Account hh =
            [select Id, Name, CreatedDate, LastModifiedDate, C501_IS_First_Visit__c, C501_IS_Most_Recent_Visit__c,
                C501_IS_Total_Visits__c, C501_IS_Homeless__c, C501_IS_Out_Of_Area__c, BillingStreet, BillingCity, BillingState, BillingPostalCode,
                C501_IS_Inactive__c, C501_IS_Notes__c, C501_IS_Source__c, C501_IS_External_Id__c, C501_IS_Adults__c,
                C501_IS_Children__c, C501_IS_Infants__c, C501_IS_Seniors__c, C501_IS_Tags__c,
                C501_IS_Staff_Notes__c, Phone, C501_IS_Proof_of_Address__c, C501_IS_Proof_of_Address_Date__c,
                (select Id, Name, FirstName, LastName, C501_IS_Age_Group__c, C501_IS_Age__c, Birthdate, C501_IS_Proof_of_Infant__c, C501_IS_Gender__c, C501_IS_Id_Number__c,
                C501_Ethnicity__c, C501_Race__c, C501_Military_Status__c, Email, Phone
                    from Contacts),
                (select C501_IS_Points_Used__c, C501_IS_Commodity_Usage_JSON__c from Visits__r where C501_IS_Visit_Date__c = THIS_MONTH)
                from Account where id = :hhid];

        if (IntakeServicesSettings.general.Track_Points__c)
            hh.C501_IS_Monthly_Points_Available__c = getMonthlyPoints( hh );

        // Get any Checkin Commodities Pending
        Intake_Services_Checkin__c fbc = Intake_Services_Checkin__c.getInstance( hhid );
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
        return
            [select C501_Start_Date__c, Id, Name, C501_Case_Worker__c
                from C501_Service_Household__c
                where C501_Household__c = :hhid
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
    public static void checkIn( Id hhid, Id contactid, Map<String, Integer> commodityUsage, String visitNotes, boolean withStaff, String visitType) {

        Intake_Services_Checkin__c fbc = new Intake_Services_Checkin__c();

        Account hh =
            [select id, Name, C501_IS_Adults__c, C501_IS_Seniors__c, C501_IS_Children__c, C501_IS_Infants__c,
                (select C501_IS_Points_Used__c from Visits__r where C501_IS_Visit_Date__c = THIS_MONTH)
                from Account where id = :hhid];

        Intake_Services_Checkin__c intake = Intake_Services_Checkin__c.getInstance( hhid );
        if (intake != null) {

            intake.Check_In_Time_With_Staff__c = system.now();
            intake.C501_With_Staff__c = withStaff;

            update intake;
        } else {
            fbc.name = hhid;
            fbc.Points_Remaining__c = getMonthlyPoints( hh );
            for (Client_Visit__c cv : hh.Visits__r)
                if (cv.C501_IS_Points_Used__c != null) fbc.Points_Remaining__c -= cv.C501_IS_Points_Used__c;

            fbc.Check_In_Time__c = system.now();
            fbc.C501_IS_Visitor__c = contactid;
            fbc.C501_IS_Visit_Type__c = visitType;

            fbc.C501_IS_Notes__c = visitNotes;
            fbc.C501_With_Staff__c = withStaff;

            if (commodityUsage != null && !commodityUsage.isEmpty()) {
                fbc.C501_IS_Commodity_Usage_JSON__c = JSON.serializePretty(commodityUsage);
            }

            insert fbc;
        }
    }

    @RemoteAction
    public static void cancelCheckIn( Id hhid ) {
        Intake_Services_Checkin__c fbc = Intake_Services_Checkin__c.getInstance( hhid );
        if (fbc != null) delete fbc;
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

        // Id Number search: back part of the Id can frequently change so stripe off back half of query to try for match
        String halfquery = query;
        if (halfquery.length() >= 16) {
            query.left(query.length() / 2);
        }

        // Expand to return all Clients for a household
        List<List<SObject>> resultList =
            [FIND :(query + '* OR ' + halfquery + '*') 
                RETURNING Contact( 
                    Name, C501_IS_Id_Number__c, MailingStreet,
                    Account.Name, Account.Id
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
        public List<Intake_Services_Box_Settings__c> boxes { get; set; }
    }

    @RemoteAction
    public static AppSettings getAppSettings() {
        AppSettings s = new AppSettings();
        s.general = IntakeServicesSettings.general;
        s.commodities = IntakeServicesSettings.commodities;
        s.boxes = IntakeServicesSettings.boxes;
        return s;
    }

    @RemoteAction
    public static Id logVisit( Id hhId, Id contactId, String boxType, Decimal checkoutWeight, Integer pointsUsed, Map<String, Integer> commodityUsage, String visitNotes) {

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

        Intake_Services_Checkin__c fbc = Intake_Services_Checkin__c.getInstance( hhid );
        c = [select id from Contact where id = :fbc.C501_IS_Visitor__c];
        if (c.isEmpty()) {
            fbc.C501_IS_Visitor__c = null;
        }

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
            C501_IS_Visit_Type__c = fbc.C501_IS_Visit_Type__c,
            C501_IS_Visit_Date__c = (fbc != null && fbc.Check_In_Time__c != null) ? fbc.Check_In_Time__c : system.now(),
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

        return cv.id;
    }
}