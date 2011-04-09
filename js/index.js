$(function() {
  var digits = [];
  var pauls_pin = "1234";

  $('#win').fadeOut(0);
  $('#fail').fadeOut(0);

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

  function win() {
    // exciting animation
    $('#win').fadeIn('fast', function() {
      setInterval(function() {
        $('#win').fadeOut('fast');
      }, 600);
    });

    // open sesame!
    openLock("Paul", function() {
      setTimeout(function() {
        closeLock();
      }, 15000); // 15 seconds
    });
  }

  function fail() {
    // menacing animation
    $('#fail').fadeIn('fast', function() {
      setInterval(function() {
        $('#fail').fadeOut('fast');
      }, 600);
    });
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
      win();
    } else {
      // FAIL!
      fail();
    }
    digits = [];
  });
});
