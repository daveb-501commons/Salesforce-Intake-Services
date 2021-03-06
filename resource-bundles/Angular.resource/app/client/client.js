/* eslint-disable linebreak-style */
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
    value: new Date('1/1/1800').getTime()
  }
});

/* Controllers for client view page */

angular.module('clientController', [
  'ngRoute',
  'angularjs-dropdown-multiselect'
]);

angular.module('clientController')
  .controller('clientController', ['$scope', '$location', '$timeout', '$window', '$routeParams', '$alert', '$q',
    'foundSettings', 'foundHousehold', 'fbSaveHousehold', 'fbSaveHouseholdMembers', 'fbSaveMemberCommodities',
    'fbSaveHouseholdAndMembers', 'fbCheckIn', 'fbVisitHistory', 'fbServiceHistory', 'fbLogVisit', 'serviceLocation',
    function($scope, $location, $timeout, $window, $routeParams, $alert, $q, foundSettings, foundHousehold,
      fbSaveHousehold, fbSaveHouseholdMembers, fbSaveMemberCommodities, fbSaveHouseholdAndMembers, fbCheckIn, fbVisitHistory, fbServiceHistory, fbLogVisit, serviceLocation) {

      $scope.contactid = $routeParams.clientContactId;

      $scope.settings = foundSettings;

      $scope.isFirstOpen = true;
      $scope.isOpen = false;
  
      $scope.data = {};
      $scope.data.household = foundHousehold;
      $scope.data.serviceLocation = serviceLocation;

      $scope.status = {};
      $scope.data.commodities = foundSettings.commodities;
      $scope.data.services = foundSettings.services;
      $scope.data.referrals = foundSettings.referrals;

      if ($scope.settings.general.trackPoints) {
        $scope.data.ptsRemaining = foundHousehold.currentPointsRemaining;
        $scope.data.ptsMonthly = foundHousehold.monthlyPointsAvailable;
        $scope.data.ratio =  Math.floor(foundHousehold.currentPointsRemaining * 100 / foundHousehold.monthlyPointsAvailable);
      }

      $scope.data.visitNotes = '';
      $scope.data.visitType = 'Select Option';
      $scope.data.visitDate = new Date();
      $scope.data.commodityDate = new Date();

      $scope.data.boxType = foundHousehold.defaultBox;
      if (foundHousehold.commodityAvailability && foundHousehold.commodityAvailability.length > 0) {
        $scope.data.commodities = foundHousehold.commodityAvailability;      
      }

      $scope.data.memberCommodities = [];
      if (foundHousehold.commodityAvailabilityMembers && foundHousehold.commodityAvailabilityMembers.length > 0) {
        $scope.data.memberCommodities = foundHousehold.commodityAvailabilityMembers;
      }

      $scope.data.visits = [];
      $scope.status.queriedVisits = false;
      $scope.data.serviceshistory = [];
      $scope.status.queriedServicesHistory = false;

      $scope.validDate = function (date) {
        return (date == null) ? false : true;
      };

      $scope.data.memberList = [];
      _.forEach(foundHousehold.members, function(v) {
        $scope.data.memberList.push({
          memberData: _.clone(v)
        });
      });

      $scope.status.hasInfant = function() {
        var members = _.map($scope.data.memberList, ($scope.status.editingMembers ? 'memberDataEditable' : 'memberData'));
        return _.some(members, {ageGroup:'Infant'});
      };

      $scope.status.proofOfInfantNeeded = function() {
        var members = _.map($scope.data.memberList, ($scope.status.editingMembers ? 'memberDataEditable' : 'memberData'));
        var infants = _.filter(members, {ageGroup:'Infant'});
        return ($scope.settings.general.proofOfInfantRequired &&
                !(_.isEmpty(infants)) && !(_.every(infants, 'proofOfInfant')));
      };

      //determine if this client has exceeded the intake services visit frequency limit and set warning message appropriately
      $scope.visitorWarningMsg = function() {
        if (!$scope.data.household.mostRecentVisitDate) {
          return;
        } else if (typeof foundSettings.general.visitFrequencyLimit == 'undefined') {
          return;
        }else if (foundSettings.general.visitFrequencyLimit.toUpperCase() === 'WEEKLY') {
        //we assume weekly means a visit once per calendar week, with the week starting on Sunday
        //first determine the day of th week of today
          if (moment().week() === moment($scope.data.household.mostRecentVisitDate).week() &&
            (moment().diff($scope.data.household.mostRecentVisitDate,'days') <= 7)) {
            return 'Heads up! This client has already visited in the past calendar week.';
          } else {
            return;
          }
        } else if (foundSettings.general.visitFrequencyLimit.toUpperCase() === 'BIWEEKLY') {
          if ( ((moment().week() === moment($scope.data.household.mostRecentVisitDate).week()) ||
          (moment().subtract(1,'weeks').week() === moment($scope.data.household.mostRecentVisitDate).week())) &&
            (moment().diff($scope.data.household.mostRecentVisitDate,'days') <= 14)) {
            return 'Heads up! This client has already visited in the past two calendar weeks.';
          } else {
            return;
          }
        } else if (foundSettings.general.visitFrequencyLimit.toUpperCase() === 'MONTHLY') {
          if (moment().month() === moment($scope.data.household.mostRecentVisitDate).month() &&
            (moment().diff($scope.data.household.mostRecentVisitDate,'days') <= 31)) {
            return 'Heads up! This client has already visited in the past calendar month.';
          } else {
            return;
          }
        } else if (foundSettings.general.visitFrequencyLimit && foundSettings.general.visitFrequencyLimit.toUpperCase().match(/^EVERY\s+.*$/)) {
          var noOfDays = parseInt(/\d+/.exec(foundSettings.general.visitFrequencyLimit));
          if (moment().diff($scope.data.household.mostRecentVisitDate,'days') < noOfDays) {
            return 'Heads up! This client has already visited in the past ' + noOfDays + ' days.';
          } else {
            return;
          }
        } else {
          return;
        }
      };

      $scope.somethingIsBeingEdited = function() {
        return ($scope.status.editingAddress && $scope.status.editingNotes && $scope.status.editingTagNotes && $scope.status.editingTags && $scope.status.editingMembers);
      };

      $scope.saveAll = function() {
        var soon = $q.defer();
        $scope.data.allData = {};
        if ($scope.status.editingAddress) {
          _.assign($scope.data.allData, $scope.data.addressData);
          $scope.status.savingAddress = true;
        }
        if ($scope.status.editingTags) {
          _.assign($scope.data.allData, $scope.data.tagsData);
          $scope.status.savingTags = true;
        }
        if ($scope.status.editingNotes) {
          _.assign($scope.data.allData, $scope.data.notesData);
          $scope.status.savingNotes = true;
        }
        if ($scope.status.editingTagNotes) {
          _.assign($scope.data.allData, $scope.data.tagnotesData);
          $scope.status.savingTagNotes = true;
        }
        if ($scope.status.editingMembers) {
          $scope.status.savingMembers = true;

          if (_.isEqual($scope.data.allData, {})) {
            fbSaveHouseholdMembers($scope.data.household.id, _.map($scope.data.memberList, 'memberDataEditable')).then(
              function(result){
                $scope.data.household = result;
                $scope.data.memberList = [];
                _.forEach(result.members, function(v) {
                  $scope.data.memberList.push({
                    memberData: _.clone(v)
                  });
                });
                $scope.status.savingMembers = false;
                $scope.status.editingMembers = false;
                soon.resolve();
              },
              function(reason){
                $scope.status.savingClient = false;
                $alert({
                  title: 'Failed to save changes.',
                  content: reason.message,
                  type: 'danger'
                });
                soon.reject();
              }
            );
          } else {
            fbSaveHouseholdAndMembers($scope.data.allData, _.map($scope.data.memberList, 'memberDataEditable')).then(
              function(result){
                $scope.data.household = result;
                $scope.data.memberList = [];
                _.forEach(foundHousehold.members, function(v) {
                  $scope.data.memberList.push({
                    memberData: _.clone(v)
                  });
                });
                $scope.status.savingMembers = false;
                $scope.status.editingMembers = false;
                soon.resolve();
              },
              function(reason){
                $scope.status.savingClient = false;
                $alert({
                  title: 'Failed to save changes.',
                  content: reason.message,
                  type: 'danger'
                });
                soon.reject();
              }
            );
          }
        } else if (!_.isEqual($scope.data.allData, {})) {
          fbSaveHousehold($scope.data.allData, $scope.settings).then(
            function(result) {
              $scope.data.household = result;
              $scope.status.savingAddress = false;
              $scope.status.editingAddress = false;
              $scope.status.savingTags = false;
              $scope.status.editingTags = false;
              $scope.status.savingNotes = false;
              $scope.status.editingNotes = false;
              $scope.status.savingTagNotes = false;
              $scope.status.editingTagNotes = false;
              soon.resolve();
            },
            function(reason) {
              $scope.status.savingAddress = false;
              $scope.status.savingTags = false;
              $scope.status.savingNotes = false;
              $scope.status.savingTagNotes = false;
              $alert({
                title: 'Failed to save changes.',
                content: reason.message,
                type: 'danger'
              });
              soon.reject();
            }
          );
        } else {
          soon.resolve();
        }
        return soon.promise;
      };

      $scope.checkIn = function() {

        if ($scope.data.visitType == 'Select Option') {
          $alert({
            title: 'Visit Reason field required!',
            type: 'danger',
            duration: 5
          });

          return;
        }

        // gather the commodity usage for this visit        
        var comms = {};
        _.forEach( $scope.data.commodities, function(v) {
          if (v.ptsUsed > 0) {
            comms[v.name] = v.ptsUsed;
          }
        });

        var servicesSelected = [];
        _.forEach( $scope.data.services, function(v) {
          if (v.selected) {
            v.selected = false;
            servicesSelected.push(v.name);
          }
        });

        var referralsSelected = [];
        _.forEach( $scope.data.referrals, function(v) {
          if (v.selected) {
            v.selected = false;
            referralsSelected.push(v.name);
          }
        });

        var dd = String($scope.data.visitDate.getDate()).padStart(2, '0');
        var mm = String($scope.data.visitDate.getMonth() + 1).padStart(2, '0'); //January is 0!
        var yyyy = $scope.data.visitDate.getFullYear();
        var safeDate = mm + '/' + dd + '/' + yyyy;

        $scope.saveAll().then(function() {

          fbCheckIn($scope.data.household.id, $scope.contactid, comms, $scope.data.household.notes || ' ', false,
            $scope.data.visitType, safeDate, servicesSelected, referralsSelected, $scope.data.serviceLocation, $scope.settings.user_email);
          $window.scrollTo(0,0);
          $alert({
            title: 'Checked in!',
            type: 'success',
            duration: 2
          });
          $timeout(function(){
            $location.url('/');
          }, 2000);
        });
      };

      $scope.recordVisit = function() {

        if ($scope.data.visitType == 'Select Option') {
          $alert({
            title: 'Visit Reason field required!',
            type: 'danger',
            duration: 5
          });

          return;
        }

        // gather the commodity usage for this visit        
        var comms = {};
        _.forEach( $scope.data.commodities, function(v) {
          if (v.ptsUsed > 0) {
            comms[v.name] = v.ptsUsed;
          }
        });

        var servicesSelected = [];
        _.forEach( $scope.data.services, function(v) {
          if (v.selected) {
            v.selected = false;
            servicesSelected.push(v.name);
          }
        });

        var referralsSelected = [];
        _.forEach( $scope.data.referrals, function(v) {
          if (v.selected) {
            v.selected = false;
            referralsSelected.push(v.name);
          }
        });

        $scope.logging = true;

        var dd = String($scope.data.visitDate.getDate()).padStart(2, '0');
        var mm = String($scope.data.visitDate.getMonth() + 1).padStart(2, '0'); //January is 0!
        var yyyy = $scope.data.visitDate.getFullYear();
        var safeDate = mm + '/' + dd + '/' + yyyy;

        fbLogVisit( $scope.data.household.id, $scope.contactid, $scope.data.boxType, 0, 0, comms,
          $scope.data.visitType, safeDate, $scope.data.visitNotes, servicesSelected, referralsSelected,
          $scope.data.serviceLocation, $scope.settings.user_email).then(
          function(result){
            $scope.logging = false;
            $window.scrollTo(0,0);
            $alert({
              title: 'Visit recorded.',
              type: 'success',
              duration: 2
            });
            $timeout(function(){
              $location.url('/');
            }, 2000);
          },
          function(reason){
            $scope.logging = false;
            $alert({
              title: 'Failed to record visit.',
              content: reason.message,
              type: 'danger'
            });
          }
        );
      };

      $scope.addMember = function() {
        $scope.data.memberList.push({
          memberData: {},
          memberDataEditable: {}
        });
      };

      $scope.cancelEdit = function() {
        $location.url('/');  // might want to go somewhere based on routing param
      };
    
      $scope.fullView = function () {
        $window.open('/one/one.app#/sObject/' + $scope.data.household.id, '_blank');
      };

      $scope.saveMemberCommodities = function() {

        $scope.status.savingMemberCommodities = true;

        var dd = String($scope.data.commodityDate.getDate()).padStart(2, '0');
        var mm = String($scope.data.commodityDate.getMonth() + 1).padStart(2, '0'); //January is 0!
        var yyyy = $scope.data.commodityDate.getFullYear();
        var safeDate = mm + '/' + dd + '/' + yyyy;

        _.forEach( $scope.data.memberCommodities, function(v) {
          if (v.ptsUsed > 0) {

            var comms = {};
            comms[v.name] = v.ptsUsed;

            fbSaveMemberCommodities($scope.data.household.id, v.ownerId, comms, safeDate, v.idNumber, $scope.data.serviceLocation, $scope.settings.user_email).then(
              function(result){
  
                // Reset values
                v.ptsUsed = 0;
                v.idNumber = '';
  
                var currentDate = new Date();
                var refreshUniqueId = String(currentDate.getTime());
                $location.url('/client/' + $scope.data.household.id + '/' + $scope.contactid + '?id=' + refreshUniqueId);
              },
              function(reason){
                $alert({
                  title: 'Failed to save changes.',
                  content: reason.message,
                  type: 'danger'
                });
              }
            );             
          }
        });

        $scope.status.savingMemberCommodities = true;
      };

      $scope.queryVisits = function() {
        if (!$scope.status.queriedVisits) {
          fbVisitHistory($scope.data.household.id).then(
            function(result) {
              $scope.data.visits = result;
              $scope.status.queriedVisits = true;
            },
            function(reason) {
              $alert({
                title: 'Failed to retrieve visit history.',
                content: reason.message,
                type: 'danger'
              });
              $scope.status.queriedVisits = true;
            }
          );
        }
      };

      $scope.queryServices = function() {
        if (!$scope.status.queriedServicesHistory) {
          fbServiceHistory($scope.data.household.id).then(
            function(result) {
              $scope.data.serviceshistory = result;
              $scope.status.queriedServicesHistory = true;
            },
            function(reason) {
              $alert({
                title: 'Failed to retrieve service history.',
                content: reason.message,
                type: 'danger'
              });
              $scope.status.queriedServicesHistory = true;
            }
          );
        }
      };


      // Populate Services History list for default open state
      $scope.queryServices();

    }]);

angular.module('clientController')
  .controller('addressController', ['$scope', '$alert', 'fbSaveHousehold',
    function($scope, $alert, fbSaveHousehold) {

      $scope.status.editingAddress = false;
      $scope.status.savingAddress = false;

      $scope.status.proofOfAddressNeeded = function() {
        return ($scope.settings.general.proofOfAddressRequired &&
                ((!$scope.data.addressData && !$scope.data.household.proofOfAddress) ||
                 ($scope.data.addressData && !$scope.data.addressData.proofOfAddress)));
      };

      $scope.editAddress = function() {
        $scope.data.addressData = {
          id: $scope.data.household.id,
          address: $scope.data.household.address,
          city: $scope.data.household.city,
          state: $scope.data.household.state,
          postalCode: $scope.data.household.postalCode,
          phone: $scope.data.household.phone,
          homeless: $scope.data.household.homeless,
          outofarea: $scope.data.household.outofarea,
          proofOfAddress: $scope.data.household.proofOfAddress
        };
        $scope.status.editingAddress = true;
      };

      $scope.saveAddress = function() {
        $scope.status.savingAddress = true;
        fbSaveHousehold($scope.data.addressData, $scope.settings).then(
          function(result) {
            $scope.data.household = result;
            $scope.status.savingAddress = false;
            $scope.status.editingAddress = false;
          },
          function(reason) {
            $scope.status.savingAddress = false;
            $alert({
              title: 'Failed to save changes.',
              content: reason.message,
              type: 'danger'
            });
          }
        );
      };

      $scope.cancelAddress = function() {
        $scope.status.editingAddress = false;
      };

    }]);

angular.module('clientController')
  .controller('notesController', ['$scope', 'fbSaveHousehold', '$alert',
    function($scope, fbSaveHousehold, $alert) {

      $scope.status.editingNotes = false;
      $scope.status.savingNotes = false;

      $scope.editNotes = function() {
        $scope.data.notesData = {
          id: $scope.data.household.id,
          notes: $scope.data.household.notes
        };
        $scope.status.editingNotes = true;
      };

      $scope.saveNotes = function() {
        $scope.status.savingNotes = true;
        fbSaveHousehold($scope.data.notesData).then(
          function(result){
            $scope.data.household = result;
            $scope.status.savingNotes = false;
            $scope.status.editingNotes = false;
          },
          function(reason){
            $scope.status.savingNotes = false;
            $alert({
              title: 'Failed to save changes.',
              content: reason.message,
              type: 'danger'
            });
          }
        );
      };

      $scope.cancelNotes = function() {
        $scope.status.editingNotes = false;
      };
    }]);

angular.module('clientController')
  .controller('tagnotesController', ['$scope', 'fbSaveHousehold', '$alert',
    function($scope, fbSaveHousehold, $alert) {

      $scope.status.editingTagNotes = false;
      $scope.status.savingTagNotes = false;

      $scope.editTagNotes = function() {
        $scope.data.tagnotesData = {
          id: $scope.data.household.id,
          tagnotes: $scope.data.household.tagnotes
        };
        $scope.status.editingTagNotes = true;
      };

      $scope.saveTagNotes = function() {
        $scope.status.savingTagNotes = true;
        fbSaveHousehold($scope.data.tagnotesData).then(
          function(result){
            $scope.data.household = result;
            $scope.status.savingTagNotes = false;
            $scope.status.editingTagNotes = false;
          },
          function(reason){
            $scope.status.savingTagNotes = false;
            $alert({
              title: 'Failed to save changes.',
              content: reason.message,
              type: 'danger'
            });
          }
        );
      };

      $scope.cancelTagNotes = function() {
        $scope.status.editingTagNotes = false;
      };
    }]);

angular.module('clientController')
  .controller('tagsController', ['$scope', 'fbSaveHousehold', '$alert', '$window',
    function($scope, fbSaveHousehold, $alert, $window) {

      $scope.status.editingTags = false;
      $scope.status.savingTags = false;
      $scope.status.acknowledgeTags = false;

      $scope.data.tagsData = {
        id: $scope.data.household.id,
        tags: $scope.data.household.tags,
        acknowledgeTags: $scope.status.acknowledgeTags
      };

      if ($scope.data.household.tags != null && $scope.data.household.tags.length > 0) {
        $window.confirm('Tag Alert!  Review tags (' + $scope.data.household.tags.toString() + ') for special handling and service restrictions.');
      }

      $scope.updateTags = function() {
        $scope.data.tagsData.tags = _.intersection(
          $scope.tagDropdown.allTags, _.pluck($scope.tagDropdown.selected, 'id') );
      };

      $scope.tagDropdown = {
        allTags: _.union($scope.settings.tags, $scope.data.household.tags),
        options: _.map(_.union($scope.settings.tags, $scope.data.household.tags),
          function(v) { return {id: v, label: v}; }),
        selected: _.map($scope.data.household.tags, function(v) { return {id: v, label: v}; }),
        events: {
          onItemSelect: $scope.updateTags,
          onItemDeselect: $scope.updateTags
        },
        settings: {
          showCheckAll: false,
          showUncheckAll: false,
          dynamicTitle: false
        }
      };

      $scope.editTags = function() {
        $scope.status.editingTags = true;
      };

      $scope.saveTags = function() {
        $scope.status.savingTags = true;
        fbSaveHousehold($scope.data.tagsData).then(
          function(result){
            $scope.data.household = result;
            $scope.status.savingTags = false;
            $scope.status.editingTags = false;
          },
          function(reason){
            $scope.status.savingTags = false;
            $alert({
              title: 'Failed to save changes.',
              content: reason.message,
              type: 'danger'
            });
          }
        );
      };

      $scope.cancelTags = function() {
        $scope.data.tagsData.tags = $scope.data.household.tags;
        $scope.tagDropdown.selected = _.map($scope.data.household.tags, function(v) { return {id: v, label: v}; });
        $scope.status.editingTags = false;
      };
    }]);

angular.module('clientController')
  .controller('memberListController', ['$scope', '$alert', 'fbSaveHouseholdMembers',
    function($scope, $alert, fbSaveHouseholdMembers) {

      $scope.status.editingMembers = false;
      $scope.status.savingMembers = false;

      $scope.checkBirthdate = function (date) {
      
        try {
          if (date.getTime() <= Date.MIN_BIRTHDATE) {
            return null;
          }
        }
        catch(err) {
          return null;
        }

        return date;
      };

      $scope.editMembers = function() {
        _.forEach($scope.data.memberList, function(v) {
          v.memberDataEditable = v.memberData;
        });
        $scope.status.editingMembers = true;
      };

      $scope.deleteMember = function(i) {
        if ($scope.data.memberList[i].memberDataEditable.id) {
          $scope.data.memberList.splice(i, 1);
        }
      };

      $scope.saveMembers = function() {
        $scope.status.savingMembers = true;
        fbSaveHouseholdMembers($scope.data.household.id, _.map($scope.data.memberList, 'memberDataEditable')).then(
          function(result){
            $scope.data.household = result;
            $scope.data.memberList = [];
            _.forEach(result.members, function(v) {
              $scope.data.memberList.push({
                memberData: _.clone(v)
              });
            });
            $scope.status.savingMembers = false;
            $scope.status.editingMembers = false;
          },
          function(reason){
            $scope.status.savingMembers = false;
            $alert({
              title: 'Failed to save changes.',
              content: reason.message,
              type: 'danger'
            });
          }
        );
      };

      $scope.cancelMembers = function() {
        $scope.status.editingMembers = false;
      };
    }]);
