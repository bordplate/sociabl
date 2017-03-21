$(function() {
	// bind 'myForm' and provide a simple callback function
	$('#postForm').ajaxForm(function() {
		location.reload();
	});
});

$('#postButton').on('click', function () {
	var $btn = $(this).button('loading')
    // business logic...
})