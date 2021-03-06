'use strict';
/*global _*/
/*global moment*/

Object.defineProperties(Date, {
  MIN_VALUE: {
    value: -8640000000000000 // A number, not a date
  },
  MAX_VALUE: {
    value: 8640000000000000
  },
  MIN_BIRTHDATE: {
    value: new Date("1/1/1800").getTime()
  }
});

angular.module('appServices', ['appServerData']);

/* Javascript Remoting Service */
angular.module('appServices')
  .factory('jsRemoting', ['$q', '$rootScope', 'controllerName',
  function($q, $rootScope, controllerName) {
    return {
      // must provide method and the right number of arguments - other arguments are optional
      invoke: function( method, args, filterFunction, options ) {
        var deferred = $q.defer();

        // set defaults for remoting options
        var vfOptions = { buffer: true, escape: false, timeout: 20000 };
        _.extend( vfOptions, options );

        // set up required arguments: method, callback, options
        var allArgs = [
          controllerName + '.' + method,
          function(result, event) {
            $rootScope.$apply(function() {
              if (event.status) {

                // apply optional filter function to the results
                if (filterFunction !== undefined) {
                  result = filterFunction(result);
                }
                deferred.resolve(result);
              } else {
                // need to check for server disconnect
                if (!navigator.onLine || !event.message || event.message.indexOf('Unable to connect to the server') >= 0) {
                  $rootScope.$broadcast('alert:offline', event);
                } else if (event.message.indexOf('Invalid session') >= 0 ||
                           event.message.indexOf('Error parsing json response') >= 0 ||
                           event.message.indexOf('Remoting request invalid for your session') >= 0) {
                  $rootScope.$broadcast('alert:nosession', event);
                }
                deferred.reject(event);
              }
            });
          },
          vfOptions
        ];

        // add in the arguments provided for this remote action
        if ( _.isArray( args ) ) {
          _.forEach( args, function(v, i) {
            allArgs.splice(i + 1, 0, v);
          });
        } else if (args !== undefined) {
          allArgs.splice(1, 0, args);
        }

        // call out to visualforce
        /* global Visualforce */
        Visualforce.remoting.Manager.invokeAction.apply(
          Visualforce.remoting.Manager, allArgs
        );
        return deferred.promise;
      }
    };
  }]);


/* Remoting data methods */

angular.module('appServices')
  .factory('fbCustomLabel', ['jsRemoting', function(jsRemoting) {
    return {
      get : function( label ) {
        return jsRemoting.invoke('getCustomLabel', label);
      }
    };
  }]);

angular.module('appServices')
  .factory('fbCheckInList', ['jsRemoting', function(jsRemoting) {
    return {
      get : function(serviceLocation) {
        return jsRemoting.invoke('getCheckedInList', serviceLocation);
      }
    };
  }]);

angular.module('appServices')
  .factory('fbCheckInListWithStaff', ['jsRemoting', function(jsRemoting) {
    return {
      get : function(serviceLocation) {
        return jsRemoting.invoke('getCheckedInListWithStaff', serviceLocation);
      }
    };
  }]);

angular.module('appServices')
  .factory('fbStats', ['jsRemoting', function(jsRemoting) {
    return {
      get : function( timeframe ) {
        return jsRemoting.invoke('getStats', timeframe);
      }
    };
  }]);

angular.module('appServices')
  .factory('fbHouseholdSearch', ['jsRemoting', function(jsRemoting) {
    return {
      get : function( query ) { //, includeInactive ) {
        return jsRemoting.invoke('queryHouseholds', query); //, includeInactive]);
      }
    };
  }]);

angular.module('appServices')
  .factory('fbSettings', ['$q', 'jsRemoting', function($q, jsRemoting) {
    var settings = {};
    return {
      get : function() {
        if (settings && settings.general) {
          var deferred = $q.defer();
          deferred.resolve(settings);
          return deferred.promise;
        } else {
          return jsRemoting.invoke('getAppSettings', [], this.translate);
        }
      },
      translate : function(result) {
        settings.general = {};
        settings.general.allowBoxSizeOverride = result.general.Allow_Box_Size_Override__c;
        settings.general.allowOverage = result.general.Allow_Overage__c;
        settings.general.checkInRequired = result.general.Check_in_Required__c;
        settings.general.monthlyBasePoints = result.general.Monthly_Base_Points__c;
        settings.general.monthlyPointsPerAdult = result.general.Monthly_Points_Per_Adult__c;
        settings.general.monthlyPointsPerChild = result.general.Monthly_Points_Per_Child__c;
        settings.general.monthlyVisitLimit = result.general.Monthly_Visit_Limit__c;
        settings.general.proofOfAddressRequired = result.general.Proof_of_Address_Required__c;
        settings.general.proofOfAddressUpdateInterval = result.general.Proof_of_Address_Update_Interval__c;
        settings.general.requireUniqueAddress = result.general.Require_Unique_Address__c;
        settings.general.showIdNumber = result.general.Show_Id__c;
        settings.general.proofOfInfantRequired = result.general.Proof_of_Infant_Required__c;
        settings.general.trackCheckoutWeight = result.general.Track_Checkout_Weight__c;
        settings.general.trackPoints = result.general.Track_Points__c;
        settings.general.visitFrequencyLimit = result.general.Visit_Frequency_Limit__c;
        settings.general.weeklyVisitLimit = result.general.Weekly_Visit_Limit__c;
        settings.general.welcomeAlert = result.general.Welcome_Alert__c;
        settings.general.welcomeMessage = result.general.Welcome_Message__c;

        settings.tags = (result.general.C501_IS_Tags__c) ? (_.map(result.general.C501_IS_Tags__c.split(';'), _.trim)) : [];

        settings.commodities = [];
        _.forEach(result.commodities, function(c){

          settings.commodities.push({
            'name': c.Name,
            'allowOverage': c.Allow_Overage__c,
            'locations': c.Locations__c,
            'monthlyLimit': c.Monthly_Limit__c,
            'individualCommodity': c.Individual_Commodity__c,
            'householdCommodity': c.Household_Commodity__c
          });
        });

        settings.services = [];
        _.forEach(result.services, function(c){

          settings.services.push({
            'name': c.Name,
            'locations': c.Locations__c,
            'selected': false,
            'column': c.Column__c
          });
        });

        settings.referrals = [];
        _.forEach(result.referrals, function(c){

          settings.referrals.push({
            'name': c.Name,
            'locations': c.Locations__c,
            'selected': false,
            'column': c.Column__c
          });
        });

        settings.boxes = [];
        _.forEach(result.boxes, function(c){
          settings.boxes.push({
            'name': c.Name,
            'minimumFamilySize': c.Minimum_Family_Size__c
          });
        });

        settings.user_email = '';

        return settings;
      }
    };
  }]);

angular.module('appServices')
  .factory('fbHouseholdDetail', ['jsRemoting', 'fbSettings',
  function(jsRemoting, fbSettings) {
    var sdo = {
      get : function( hhid ) {
        return jsRemoting.invoke('getHouseholdDetail', hhid, this.translate);
      },
      getSObject: function( hh ) {
        var sobj = {
          Name: hh.name,
          C501_IS_Total_Visits__c: hh.totalVisits,
          C501_IS_Monthly_Points_Available__c: hh.monthlyPointsAvailable,
          C501_IS_Tags__c: hh.tags ? hh.tags.join(';') : undefined,
          BillingStreet: hh.address,
          BillingCity: hh.city,
          BillingState: hh.state,
          BillingPostalCode: hh.postalCode,
          Phone: hh.phone,
          C501_IS_Homeless__c: hh.homeless,
          C501_IS_Out_Of_Area__c: hh.outofarea,
          C501_IS_Notes__c: hh.notes,
          C501_IS_Tag_Notes__c: hh.tagnotes,
          C501_IS_Source__c: hh.source,
          C501_IS_External_Id__c: hh.externalId,
          C501_IS_Adults__c: hh.adults,
          C501_IS_Children__c: hh.children,
          C501_IS_Infants__c: hh.infants,
          C501_IS_Seniors__c: hh.seniors,
          CreatedDate: hh.createdDate,
          C501_IS_First_Visit__c: hh.firstVisitDate,
          C501_IS_Most_Recent_Visit__c: hh.mostRecentVisitDate,
          C501_IS_Proof_of_Address__c: hh.proofOfAddress,
          C501_IS_Inactive__c: hh.inactive,
          C501_IS_Pending_Commodity_Usage_JSON__c: hh.C501_IS_Pending_Commodity_Usage_JSON__c,
          C501_IS_Pending_Notes__c: hh.C501_IS_Pending_Notes__c
        };
        if (hh.id) sobj.Id = hh.id;
        return sobj;
      },

      getMemberSObject : function( mobj ) {
        var sobj = {
          FirstName: mobj.firstName,
          LastName: mobj.lastName,
          C501_IS_Age_Group__c: mobj.ageGroup,
          C501_IS_Id_Number__c: mobj.Id_Number,
          C501_IS_Gender__c: mobj.gender,
          C501_IS_Age__c: mobj.age,
          birthdate: (mobj.birthdate) ? mobj.birthdate.getTime() : Date.MIN_BIRTHDATE,
          C501_Ethnicity__c: mobj.ethnicity,
          C501_Race__c :mobj.race,
          C501_Military_Status__c :mobj.veteran,
          Email :mobj.email,
          Phone :mobj.phone,
          C501_IS_Proof_of_Infant__c: mobj.proofOfInfant
        };
        if (mobj.id) sobj.Id = mobj.id;
        return sobj;
      },

      translate : function( result ) {
        var client = {
          id: result.Id,
          name: result.Name,
          fullAddress: String.format('{0}, {1}, {2} {3}', 
            (result.BillingStreet != null) ? result.BillingStreet : '',
            (result.BillingCity != null) ? result.BillingCity : '',
            (result.BillingState != null) ? result.BillingState : '',
            (result.BillingPostalCode != null) ? result.BillingPostalCode : ''),
          totalVisits: result.C501_IS_Total_Visits__c,
          monthlyPointsAvailable: result.C501_IS_Monthly_Points_Available__c,
          tags: (result.C501_IS_Tags__c) ? (_.map(result.C501_IS_Tags__c.split(';'), _.trim)) : null,
          address: result.BillingStreet,
          city: result.BillingCity,
          state: result.BillingState,
          postalCode: result.BillingPostalCode,
          phone: result.Phone,
          homeless: result.C501_IS_Homeless__c,
          outofarea: result.C501_IS_Out_Of_Area__c,
          notes: result.C501_IS_Notes__c,
          tagnotes: result.C501_IS_Tag_Notes__c,
          source: result.C501_IS_Source__c,
          externalId: result.C501_IS_External_Id__c,
          adults: result.C501_IS_Adults__c,
          children: result.C501_IS_Children__c,
          infants: result.C501_IS_Infants__c,
          seniors: result.C501_IS_Seniors__c,
          createdDate: result.CreatedDate,
          firstVisitDate: result.C501_IS_First_Visit__c,
          mostRecentVisitDate: result.C501_IS_Most_Recent_Visit__c,
          proofOfAddressDate: result.C501_IS_Proof_of_Address_Date__c,
          proofOfAddress: result.C501_IS_Proof_of_Address__c,
          inactive: result.C501_IS_Inactive__c,
          pendingcommodityusage: result.C501_IS_Pending_Commodity_Usage_JSON__c,
          pendingnotes: result.C501_IS_Pending_Notes__c
        };

        // add up the household members
        if (!client.adults) { client.adults = 0; }
        if (!client.seniors) { client.seniors = 0; }
        if (!client.children) { client.children = 0; }
        if (!client.infants) { client.infants = 0; }
        client.totalMembers = client.adults + client.seniors + client.children + client.infants;

        client.commodityUsageMembers = {};

        // build list of members
        client.members = [];
        _.forEach( result.Contacts, function(c) {

          _.forEach( result.Visits__r, function(visit) {

            if (visit.C501_IS_Commodity_Usage_JSON__c && visit.C501_IS_Related_To_Contact__c == c.Id) {
              _.forEach(angular.fromJson(visit.C501_IS_Commodity_Usage_JSON__c), function(value, key) {
                if ( (key + c.Id) in client.commodityUsageMembers) {
                  client.commodityUsageMembers[key + c.Id] += value;
                } else {
                  client.commodityUsageMembers[key + c.Id] = value;
                }
              });
            }
          });
  
          client.members.push({
            id: c.Id,
            name: c.Name,
            firstName: c.FirstName,
            lastName: c.LastName,
            ageGroup: c.C501_IS_Age_Group__c,
            Id_Number: c.C501_IS_Id_Number__c,
            gender: c.C501_IS_Gender__c,
            age: c.C501_IS_Age__c,
            ethnicity: c.C501_Ethnicity__c,
            race: c.C501_Race__c,
            veteran: c.C501_Military_Status__c,
            email: c.Email,
            phone: c.Phone,
            // c.Birthdate + 12 hours to make sure rounding to correct day since Date parses the value as GMT then converts to Browser Time Zone (Pacific)
            birthdate: (c.Birthdate) ? new Date(c.Birthdate + (12 * 60 * 60 * 1000)) : Date.MIN_BIRTHDATE,
            proofOfInfant: c.C501_IS_Proof_of_Infant__c
          });
        });

        client.commodityUsage = {};

        // add up points and commodities used in previous visits this month
        var pointsUsed = 0;
        client.visitsThisMonth = (result.Visits__r ? result.Visits__r.length : 0);
        _.forEach( result.Visits__r, function(visit) {
          if (visit.C501_IS_Points_Used__c) {
            pointsUsed += v.C501_IS_Points_Used__c;
          }

          // TODO: try catch? json could be bogus
          if (visit.C501_IS_Commodity_Usage_JSON__c && (visit.C501_IS_Related_To_Contact__c == null || visit.C501_IS_Related_To_Contact__c == '')) {
            _.forEach(angular.fromJson(visit.C501_IS_Commodity_Usage_JSON__c), function(value, key) {
              if (key in client.commodityUsage) {
                client.commodityUsage[key] += value;
              } else {
                client.commodityUsage[key] = value;
              }
            });
          }
        });

        // Check the checkin queue for pending commodities
        client.commodityPending = {};
        if (client.pendingcommodityusage != null) {
          _.forEach( angular.fromJson( client.pendingcommodityusage ), function(value, key) {
              client.commodityPending[key] = value;
          });
        }

        // subtract commodity usage to get the current available commodities
        fbSettings.get().then(
          function(settings){

            client.commodityAvailability = [];
            _.forEach(settings.commodities, function(commodity) {

              var householdCommodity = _.clone(commodity);

              householdCommodity.ptsUsed = 0;
              if (client.commodityPending && (householdCommodity.name in client.commodityPending) ) {
                householdCommodity.ptsUsed = client.commodityPending[householdCommodity.name];
              }

              householdCommodity.remaining = householdCommodity.monthlyLimit;
              if (client.commodityUsage && (householdCommodity.name in client.commodityUsage) ) {
                householdCommodity.remaining -= client.commodityUsage[householdCommodity.name];
              }

              client.commodityAvailability.push(householdCommodity);     
            });

            client.commodityAvailabilityMembers = [];
            _.forEach(client.members, function(c) {

              _.forEach(settings.commodities, function(commodity) {

                var memberCommodity = _.clone(commodity);
  
                memberCommodity.remaining = memberCommodity.monthlyLimit;
                if( client.commodityUsageMembers && ( (memberCommodity.name + c.id) in client.commodityUsageMembers) ) {
                  memberCommodity.remaining -= client.commodityUsageMembers[memberCommodity.name + c.id];
                }

                client.commodityAvailabilityMembers.push({
                  'ownerName': c.name,
                  'ownerId': c.id,
                  'idNumber': '',
                  'name': memberCommodity.name,
                  'allowOverage': memberCommodity.allowOverage,
                  'locations': memberCommodity.locations,
                  'monthlyLimit': memberCommodity.monthlyLimit,
                  'remaining': memberCommodity.remaining,
                  'ptsUsed': 0,
                  'individualCommodity': memberCommodity.individualCommodity,
                  'householdCommodity': memberCommodity.householdCommodity
                });
              });               
            });

            // TODO: add a box override
            // figure which box this client gets
            client.defaultBox = '';
            _.forEach( settings.boxes, function(v) {
              if (client.defaultBox === '' ||
                  (v.minimumFamilySize && v.minimumFamilySize <= client.totalMembers)) {
                client.defaultBox = v.name;
              }
            });

            // do we need proof of address?
            if (settings.general.proofOfAddressRequired) {

              var proofOfAddressCutoffDate =
                (settings.general.proofOfAddressUpdateInterval == null) ? null :
                moment().subtract(settings.general.proofOfAddressUpdateInterval, 'months');

              var proofOfAddressNeeded =
                (!proofOfAddressCutoffDate || client.proofOfAddressDate == undefined ||
                  moment(client.proofOfAddressDate).isBefore(proofOfAddressCutoffDate));

              // if the proof is old, clear it out
              if (proofOfAddressNeeded) {
                client.proofOfAddress = null;
              }
            }
            
            if (settings.general.trackPoints) {
              client.currentPointsUsed = pointsUsed;
              client.currentPointsRemaining = client.monthlyPointsAvailable - pointsUsed;              
            }
          }
        );

        return client;
      }
    };
    
    return sdo;
  }]);

angular.module('appServices')
  .factory('fbSaveHousehold', ['jsRemoting', 'fbHouseholdDetail', function(jsRemoting, fbHouseholdDetail) {
    return function( hh ) {
      if ( hh ) {
        return jsRemoting.invoke('saveHousehold', [fbHouseholdDetail.getSObject(hh)], fbHouseholdDetail.translate);
      } else {
        return;  // need to return a promise, i think
      }
    };
  }]);

angular.module('appServices')
  .factory('fbSaveHouseholdMembers', ['jsRemoting', 'fbHouseholdDetail', function(jsRemoting, fbHouseholdDetail) {
    return function( hhid, members ) {
      var memberList = _.map(members, fbHouseholdDetail.getMemberSObject);
      return jsRemoting.invoke('saveHouseholdMembers', [hhid, memberList], fbHouseholdDetail.translate);
    };
  }]);

angular.module('appServices')
  .factory('fbSaveMemberCommodities', ['jsRemoting', function(jsRemoting) {
      return function( hhid, contactid, comms, commodityDate, idNumber, serviceLocation, createdBy ) {
        return jsRemoting.invoke('saveMemberCommodities', [hhid, contactid, comms, commodityDate, idNumber, serviceLocation, createdBy]);
      };
  }]);

angular.module('appServices')
  .factory('fbSaveHouseholdAndMembers', ['jsRemoting', 'fbHouseholdDetail', function(jsRemoting, fbHouseholdDetail) {
    return function( hh, members ) {
      var memberList = _.map(members, fbHouseholdDetail.getMemberSObject);
      return jsRemoting.invoke('saveHouseholdAndMembers', [fbHouseholdDetail.getSObject(hh), memberList], fbHouseholdDetail.translate);
    };
  }]);

angular.module('appServices')
  .factory('fbCheckIn', ['jsRemoting', function(jsRemoting) {
      return function( hhid, contactid, commodities, notes, withStaff, visitType, visitDate, services, referrals, serviceLocation, createdBy ) {
        return jsRemoting.invoke('checkIn', [hhid, contactid, commodities, notes, withStaff, visitType, visitDate, services, referrals, serviceLocation, createdBy]);
      };
  }]);

angular.module('appServices')
  .factory('fbVisitHistory', ['jsRemoting', function(jsRemoting) {
    return function( hhid ) {
      return jsRemoting.invoke('getVisitHistory', hhid, function(result){
        var visits = [];
        _.forEach(result, function(result){
          visits.push({
            'date': result.C501_IS_Visit_Date__c,
            'visitor': (result.C501_IS_Visitor__r) ? result.C501_IS_Visitor__r.Name : '',
            'boxType': result.C501_IS_Box_Type__c,
            'ptsUsed': result.C501_IS_Points_Used__c,
            'checkoutWeight' : result.C501_IS_Checkout_Weight__c,
            'notes': result.C501_IS_Notes__c
          });
        });
        return visits;
      });
    };
  }]);

  angular.module('appServices')
  .factory('fbServiceHistory', ['jsRemoting', function(jsRemoting) {
    return function( hhid ) {
      return jsRemoting.invoke('getServiceHistory', hhid, function(result){
        var services = [];
        _.forEach(result, function(result){
          
          // Filter out Change Requests
          if (result.Name.indexOf('Change') < 0) {
            services.push({
              // + 12 hours to make sure rounding to correct day since Date parses the value as GMT then converts to Browser Time Zone (Pacific)
              'startdate': (result.C501_Start_Date__c == null) ? null : new Date(result.C501_Start_Date__c + (12 * 60 * 60 * 1000)),
              'enddate': (result.C501_End_Date__c == null) ? null : new Date(result.C501_End_Date__c + (12 * 60 * 60 * 1000)),
              'isactive': result.C501_IsActive__c,
              'name': result.Name,
              'caseworker': result.C501_Case_Worker__c
            });
          }
        });

        return services;
      });
    };
  }]);

angular.module('appServices')
  .factory('fbCancelCheckIn', ['jsRemoting', function(jsRemoting) {
    return function( hhid ) {
      return jsRemoting.invoke('cancelCheckIn', hhid);
    };
  }]);

angular.module('appServices')
  .factory('fbLogVisit', ['jsRemoting', function(jsRemoting) {
    return function( hhid, contactid, boxType, checkoutWeight, pointsUsed, commodities, visitType, visitDate, notes, services, referrals, serviceLocation, createdBy ) {
      return jsRemoting.invoke('logVisit', [hhid, contactid, boxType, checkoutWeight, pointsUsed, commodities, visitType, visitDate, notes, services, referrals, serviceLocation, createdBy]);
    };
  }]);
