/* eslint-disable linebreak-style */
'use strict';

/* Controllers for log visit page */

angular.module('logVisitController', [
  'ngRoute'
]);

angular.module('logVisitController')
  .controller('logVisitController', ['$scope', '$routeParams', '$timeout', '$window', '$location', 'foundHousehold', 'foundSettings', 'fbLogVisit', 'fbCustomLabel', '$alert', 'serviceLocation',
    function($scope, $routeParams, $timeout, $window, $location, foundHousehold, foundSettings, fbLogVisit, fbCustomLabel, $alert, serviceLocation) {

      $scope.contactid = $routeParams.clientContactId;
      
      $scope.data = {};
      $scope.data.household = foundHousehold;
      $scope.data.serviceLocation = serviceLocation;

      $scope.visitNotes = '';
      $scope.data.visitDate = new Date();
      $scope.data.visitType = 'Select Option';

      $scope.settings = foundSettings;

      $scope.commodities = foundSettings.commodities;
      $scope.services = foundSettings.services;
      $scope.referrals = foundSettings.referrals;

      $scope.logging = false;
      $scope.addressEdit = false;

      $scope.ptsUsed = 0;
      $scope.checkoutWeight = 0.0;
      $scope.ptsRemaining = foundHousehold.currentPointsRemaining;
      $scope.ptsMonthly = foundHousehold.monthlyPointsAvailable;
      $scope.ratio =  Math.floor($scope.ptsRemaining * 100 / $scope.ptsMonthly);
      $scope.boxType = foundHousehold.defaultBox;

      $scope.commodities = foundHousehold.commodityAvailability;
    
      fbCustomLabel.get( 'C501_IS_Box_Type__c' ).then(
        function(result){
          $scope.Label_Box_Type = result;
        }
      );

      $scope.recordVisit = function() {

        // gather the commodity usage for this visit        
        var comms = {};
        _.forEach( $scope.commodities, function(v) {
          if (v.ptsUsed > 0) {
            comms[v.name] = v.ptsUsed;
          }
        });

        var servicesSelected = [];
        _.forEach( $scope.services, function(v) {
          if (v.selected) {
            v.selected = false;
            servicesSelected.push(v.name);
          }
        });

        var referralsSelected = [];
        _.forEach( $scope.referrals, function(v) {
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

        fbLogVisit( $scope.data.household.id, $scope.contactid, $scope.boxType, $scope.checkoutWeight, $scope.ptsUsed, comms,
          $scope.data.visitType, safeDate, $scope.visitNotes, servicesSelected, referralsSelected, $scope.data.serviceLocation, $scope.settings.user_email).then(
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
    }]);
