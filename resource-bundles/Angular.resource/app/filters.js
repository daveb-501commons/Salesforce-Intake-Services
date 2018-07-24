'use strict';

/* Filters */

angular.module('IntakeServicesFilters', [])
  .filter('checkmark', function() {
    return function(input) {
      return input ? '\u2713' : '\u2718';
    };
  });
