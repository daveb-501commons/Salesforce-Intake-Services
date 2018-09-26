'use strict';

/* Controllers for log visit page */

angular.module('logVisitController', [
    'ngRoute'
  ]);

angular.module('logVisitController')
  .controller('logVisitController', ['$scope', '$routeParams', '$timeout', '$window', '$location', 'foundHousehold', 'foundSettings', 'fbLogVisit', 'fbCustomLabel', '$alert',
    function($scope, $routeParams, $timeout, $window, $location, foundHousehold, foundSettings, fbLogVisit, fbCustomLabel, $alert) {

    $scope.contactid = $routeParams.clientContactId;
      
    $scope.data = {};
    $scope.data.household = foundHousehold;

    $scope.settings = foundSettings;
    $scope.commodities = foundSettings.commodities;

    $scope.logging = false;
    $scope.addressEdit = false;

    $scope.ptsUsed = 0;
    $scope.checkoutWeight = 0.0;
    $scope.ptsRemaining = foundHousehold.currentPointsRemaining;
    $scope.ptsMonthly = foundHousehold.monthlyPointsAvailable;
    $scope.ratio =  Math.floor($scope.ptsRemaining * 100 / $scope.ptsMonthly);
    $scope.boxType = foundHousehold.defaultBox;
    $scope.commodities = foundHousehold.commodityAvailability;

    $scope.data.new_services = {
      Basic_Food_Applications: false,
      Eviction_Prevention_Screening: false,
      Ferry_Pass: false,
      Health_Plan_Finder: false,
      Housing_Intake: false,
      Landlord_Tenant_Education: false,
      Salvation_Army_Voucher: false
    };
    $scope.data.new_referrals = {
      Adult_Education: false,
      Adult_Education: false,
      Childcare: false,
      Coordinated_Entry: false,
      Domestic_Violence_Services: false,
      DSHS: false,
      Early_Head_Start: false,
      Emergency_Child_Care_Voucher: false,
      Employment: false,
      Energy_Assistance: false,
      Financial_Literacy: false,
      Food_Resources: false,
      Head_Start_FORWARDSLASH_ECEAP: false,
      Healthcare: false,
      Home_Improvement: false,
      Housing: false,
      Kinship: false,
      Landlord_Tenant: false,
      Mental_Health: false,
      Other_Early_Learning: false,
      Other_Legal: false,
      Other_Utility: false,
      SEAS: false,
      Veterans_Services: false,
      Youth_Programs: false
    };

    $scope.visitNotes = '';
    if (foundHousehold.pendingnotes != null && foundHousehold.pendingnotes.length > 0) {
      $scope.visitNotes = foundHousehold.pendingnotes;
    }
    
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

      $scope.logging = true;

      fbLogVisit( $scope.data.household.id, $scope.contactid, $scope.boxType, $scope.checkoutWeight, $scope.ptsUsed, comms, $scope.visitNotes).then(
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
