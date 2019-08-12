public with sharing class IntakeServicesSettings {

    /**************************************************************************
    * The pattern is to create a static property for each settings object
    * and provide defaults if it is a test. Each setting will be instantiated
    * only once per transaction.
    *
    * To refer to a setting in the first section below, use:
    *   IntakeServicesSettings.general.Monthly_Visit_Limit__c
    *
    * For a list setting, specify the value you want:
    *   IntakeServicesSettings.commodity('Bread').Monthly_Limit__c
    *
    ***************************************************************************/

    public static Intake_Services_Settings__c general {
        get {
            if (general == null) {
                general = Intake_Services_Settings__c.getOrgDefaults();
                if (Test.isRunningTest()) {
                    // defaults for testing
                    general.Allow_Box_Size_Override__c = false;
                    general.Allow_Overage__c = false;
                    general.Monthly_Base_Points__c = 30;
                    general.Monthly_Points_Per_Adult__c = 10;
                    general.Monthly_Points_Per_Child__c = 10;
                    general.Check_in_Required__c = false;
                    general.Proof_of_Address_Required__c = true;
                    general.Proof_of_Address_Update_Interval__c = 12;
                    general.Require_Unique_Address__c = false;
                    general.Show_Id__c = false;
                    general.Proof_of_Infant_Required__c = true;
                    general.Track_Checkout_Weight__c = true;
                    general.Track_Points__c = true;
                    general.C501_IS_Tags__c = 'Special Diet; Spanish Speaker';
                    general.Welcome_Alert__c = 'Hello!';
                    general.Welcome_Message__c = 'Welcome to the intake services.';
                }
            }
            return general;
        }
        set;
    }

    public static list<Intake_Services_Commodity__c> commodities {
        get {
            if (commodities == null) {
                commodities = (!Test.isRunningTest()) ?
                    [select name, Monthly_Limit__c, Allow_Overage__c, Locations__c from Intake_Services_Commodity__c order by Sort_Order__c, name] :
                    new List<Intake_Services_Commodity__c>{
                        new Intake_Services_Commodity__c(
                            Name = 'Meat',
                            Monthly_Limit__c = 5,
                            Sort_Order__c = 0,
                            Allow_Overage__c = false,
                            Locations__c = 'Seattle' ),
                        new Intake_Services_Commodity__c(
                            Name = 'Bread',
                            Monthly_Limit__c = 3,
                            Sort_Order__c = 1,
                            Allow_Overage__c = true,
                            Locations__c = 'Seattle' )
                    };
            }

            System.debug('*****IntakeServicesSettings::commodities ' + commodities);
            return commodities;
        }
        set;
    }

    public static list<Intake_Services__c> services {
        get {
            if (services == null) {
                services = (!Test.isRunningTest()) ?
                    [select name, Sort_Order__c, Locations__c, Column__c, Selected__c from Intake_Services__c order by Sort_Order__c, name] :
                    new List<Intake_Services__c>{
                        new Intake_Services__c(
                            Name = 'Foodbank',
                            Column__c = 1,
                            Sort_Order__c = 0,
                            Locations__c = 'Seattle' ),
                        new Intake_Services__c(
                            Name = 'Housing',
                            Column__c = 2,
                            Sort_Order__c = 1,
                            Locations__c = 'Seattle' )
                    };
            }

            System.debug('*****IntakeServicesSettings::services ' + services);
            return services;
        }
        set;
    }

    public static list<Intake_Referrals__c> referrals {
        get {
            if (referrals == null) {
                referrals = (!Test.isRunningTest()) ?
                    [select name, Sort_Order__c, Locations__c, Column__c, Selected__c from Intake_Referrals__c order by Sort_Order__c, name] :
                    new List<Intake_Referrals__c>{
                        new Intake_Referrals__c(
                            Name = 'Dentist',
                            Column__c = 1,
                            Sort_Order__c = 0,
                            Locations__c = 'Seattle' ),
                        new Intake_Referrals__c(
                            Name = 'Doctor',
                            Column__c = 2,
                            Sort_Order__c = 1,
                            Locations__c = 'Seattle' )
                    };
            }

            System.debug('*****IntakeServicesSettings::referrals ' + referrals);
            return referrals;
        }
        set;
    }

    public static list<Intake_Services_Box_Settings__c> boxes {
        get {
            if (boxes == null) {
                boxes = (!Test.isRunningTest()) ?
                    [select name, Minimum_Family_Size__c from Intake_Services_Box_Settings__c order by Minimum_Family_Size__c asc nulls last, name] :
                    new List<Intake_Services_Box_Settings__c>{
                        new Intake_Services_Box_Settings__c(
                            Name = 'Small',
                            Minimum_Family_Size__c = 1 ),
                        new Intake_Services_Box_Settings__c(
                            Name = 'Large',
                            Minimum_Family_Size__c = 3 ),
                        new Intake_Services_Box_Settings__c(
                            Name = 'No Cook' )
                    };
            }
            return boxes;
        }
        set;
    }
}