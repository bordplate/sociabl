$(function() {
	// bind 'myForm' and provide a simple callback function
	$('#followForm').ajaxForm(function() {
		location.reload();
	});
});