$(function() {
  var digits = [];
  var pauls_pin = "1234";

  jQuery.fn.flash = function(first, second, complete) {
    var self = this;
    self.animate( { opacity: 0.5 }, first, 'linear', function() {
      self.animate( { opacity: 1.0 }, second, 'linear', complete);
    });
  }

  function openLock(name, callback) {
    $.ajax({
      url: 'http://api.pachube.com/v1/feeds/22380.csv?key=ZwY_-EBddMqXB4GMZy3ATGCMTv6Nq26U1ua864LB-E8',
      type: 'PUT',
      processData: false,
      data: "1,Paul",
      success: callback
    });
  }

  function closeLock(callback) {
    $.ajax({
      url: 'http://api.pachube.com/v1/feeds/22380/datastreams/lock_state.csv?key=ZwY_-EBddMqXB4GMZy3ATGCMTv6Nq26U1ua864LB-E8',
      type: 'PUT',
      processData: false,
      data: "1",
      success: callback
    });
  }

  function pulse(first, second) {
    $('a').flash(first, second);
  }

  $('.number').click(function() {
    digits.push($(this).attr('id'));
    //console.log(digits);
  });

  $('#cancel').click(function() {
    digits = [];
  });

  $('#ok').click(function() {
    if (digits.join('') == pauls_pin) {
      // WIN!
      openLock("Paul", function() {
        setTimeout(function() {
          closeLock();
        }, 15000); // 15 seconds
      });
    } else {
      // FAIL!
    }
    digits = [];
  });
});
