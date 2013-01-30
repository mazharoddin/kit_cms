markdown_settings = {
	previewParserPath:	'/forums/post/preview',
        previewParserVar: 'body',
	onShiftEnter:		{keepDefault:false, openWith:'\n\n'},
	markupSet: [
		{name:'Bold', key:'B', openWith:'**', closeWith:'**'},
		{name:'Underline', key:'U', openWith:'_', closeWith:'_'},
		{separator:' ' },
		{name:'List', openWith:'- ' },
		{name:'Numeric List', openWith:function(markItUp) {
			return markItUp.line+'. ';
		}},
		{separator:' ' },
		{name:'Image', key:'I', replaceWith:'![]([![Url:!:http://]!])'},
		{name:'Link', key:'L', openWith:'[', closeWith:']([![Url:!:http://]!])', placeHolder:'Your text to link here...' },
		{separator:' '},	
		{name:'Quotes', openWith:'> '},
		{name:'Formatted', openWith:'(!(\t|!|`)!)', closeWith:'(!(`)!)'},
		{separator:' '},
		{name:'Preview', call:'preview', className:"preview"}
	]
}

miu = "None";

function markdown_editor(field) {
}
