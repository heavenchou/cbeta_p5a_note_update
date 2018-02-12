##########################################################################
#
# 把 CBETA 舊校勘修訂成新的校勘
# 1. <note resp="xxxx">ＡＢＣＤＥ</note>
#    轉成：
#    <note n="xxxxxxx" resp="xxxx" type="add">ＡＢＣＤＥ</note>
#
##########################################################################

use utf8;
use Cwd;
use strict;
use XML::DOM;
my $parser = new XML::DOM::Parser;

my $SourcePath = "c:/cbwork/xml-p5a/GA/GA026";			# 初始目錄, 最後不用加斜線 /
my $OutputPath = "c:/temp/xml-p5a-new/GA/GA026";		# 目地初始目錄, 如果有需要的話. 最後不用加斜線 /
my $log_file1 = "5_make_note_log.txt";		# log 檔 , 記錄 note in note
my $log_file2 = "5_make_app_log.txt";		# log 檔 , 記錄 note in note
my $log_file3 = "5_make_choice_log.txt";	# log 檔 , 記錄 note in note
my $log_file4 = "5_check_jk_log.txt";		# log 檔 , 記錄 note in note

my $MakeOutputPath = 1;		# 1 : 產生對應的輸出目錄
my $IsIncludeSubDir = 1;	# 1 : 包含子目錄 0: 不含子目錄
my $FilePattern = "*.xml";		# 要找的檔案類型

my $lb_num;				# 行首頁欄行
my $lb_serial = 0;		# 每一行的序號
my $bookver = "【大】";

open LOG1, ">:utf8", $log_file1;
open LOG2, ">:utf8", $log_file2;
open LOG3, ">:utf8", $log_file3;
open LOG4, ">:utf8", $log_file4;
SearchDir($SourcePath, $OutputPath);
close LOG1;
close LOG2;
close LOG3;
close LOG4;

##########################################################################

sub SearchDir
{
	my $ThisDir = shift;		# 新的所在的目錄
	my $ThisOutputDir = shift;	# 新的的輸出目錄
	
	print "find dir <$ThisDir>\n";
	
	if($MakeOutputPath)	# 如果需要建立對應子目錄
	{
		mkdir($ThisOutputDir) unless(-d $ThisOutputDir);
	}
	
	my $myPath = getcwd();		# 目前路徑
	chdir($ThisDir);
	my @files = glob($FilePattern);
	chdir($myPath);				# 回到目前路徑
	
	foreach my $file (sort(@files))
	{
		next if($file =~ /^\./);		# 不要 . 與 ..
		my $NewFile = $ThisDir . "/" . $file ;
		my $NewOutputFile = $ThisOutputDir . "/" . $file ;
		if (-f $NewFile)
		{
			SearchFile($NewFile , $NewOutputFile);
		}
	}
	return unless($IsIncludeSubDir);	# 若不搜尋子目錄就離開
	
	opendir (DIR, "$ThisDir");
	my @files = readdir(DIR);
	closedir(DIR);
	
	foreach my $file (sort(@files))
	{
		next if($file =~ /^\./);
		my $NewDir = $ThisDir . "/" . $file ;
		my $NewOutputDir = $ThisOutputDir . "/" . $file ; 
		if (-d $NewDir)
		{
			SearchDir($NewDir, $NewOutputDir);
		}
	}	
}

##########################################################################

sub SearchFile
{
	local $_;
	my $file = shift;
	my $outfile = shift;
	
	# 判斷版本

	if($file =~ /[\\\/]A[\\\/]/) { $bookver = "【金藏】";}
	elsif($file =~ /[\\\/]B[\\\/]/) { $bookver = "【補編】";}
	elsif($file =~ /[\\\/]C[\\\/]/) { $bookver = "【中華】";}
	elsif($file =~ /[\\\/]D[\\\/]/) { $bookver = "【國圖】";}
	elsif($file =~ /[\\\/]DA[\\\/]/) { $bookver = "【道安】";}
	elsif($file =~ /[\\\/]F[\\\/]/) { $bookver = "【房山】";}
	elsif($file =~ /[\\\/]G[\\\/]/) { $bookver = "【教藏】";}
	elsif($file =~ /[\\\/]GA[\\\/]/) { $bookver = "【志彙】";}
	elsif($file =~ /[\\\/]GB[\\\/]/) { $bookver = "【志叢】";}
	elsif($file =~ /[\\\/]I[\\\/]/) { $bookver = "【佛拓】";}
	elsif($file =~ /[\\\/]J[\\\/]/) { $bookver = "【嘉興】";}
	elsif($file =~ /[\\\/]K[\\\/]/) { $bookver = "【麗】";}
	elsif($file =~ /[\\\/]L[\\\/]/) { $bookver = "【龍】";}
	elsif($file =~ /[\\\/]M[\\\/]/) { $bookver = "【卍正】";}
	elsif($file =~ /[\\\/]N[\\\/]/) { $bookver = "【南傳】";}
	elsif($file =~ /[\\\/]P[\\\/]/) { $bookver = "【北藏】";}
	elsif($file =~ /[\\\/]S[\\\/]/) { $bookver = "【宋遺】";}
	elsif($file =~ /[\\\/]T[\\\/]/) { $bookver = "【大】";}
	elsif($file =~ /[\\\/]U[\\\/]/) { $bookver = "【洪武】";}
	elsif($file =~ /[\\\/]X[\\\/]/) { $bookver = "【卍續】";}
	elsif($file =~ /[\\\/]Y[\\\/]/) { $bookver = "【印順】";}
	elsif($file =~ /[\\\/]ZS[\\\/]/) { $bookver = "【正史】";}
	elsif($file =~ /[\\\/]ZW[\\\/]/) { $bookver = "【藏外】";}
	elsif($file =~ /[\\\/]ZY[\\\/]/) { $bookver = "【智諭】";}
		
	#### 要做的事

	print $file . "\n";
	print LOG1 $file . "=============== \n";
	print LOG2 $file . "=============== \n";
	print LOG3 $file . "=============== \n";
	print LOG4 $file . "=============== \n";

	my $text = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
	$text .= ParserXML($file);

	open OUT, ">:utf8", $outfile;
	print OUT $text;
	close OUT;
}

##########################################################################
# 處理 XML
sub ParserXML
{
    my $file = shift;
	my $doc = $parser->parsefile($file);
	
	my $root = $doc->getDocumentElement();
	my $text = parseNode($root);	# 全部進行分析
	
	$doc->dispose;
    return $text;
}

# 處理節點
sub parseNode
{
    my $node = shift;
    my $text = "";
    my $nodeTypeName = $node->getNodeTypeName;
	if ($nodeTypeName eq "ELEMENT_NODE") 
    {
        # 處理標記
        my $tag_name = $node->getNodeName();	# 取得標記名稱 

		# 處理標記
        if($tag_name eq "app") { $text = tag_app($node); }
    	elsif($tag_name eq "choice") { $text = tag_choice($node); }
    	elsif($tag_name eq "lb") { $text = tag_lb($node); }
        elsif($tag_name eq "note") { $text = tag_note($node); }
		else { $text = tag_default($node); }				# 處理一般標記
    }
	elsif ($nodeTypeName eq "TEXT_NODE") 
    {
        # 處理文字
        $text = text_handler($node);
    }   
	elsif ($nodeTypeName eq "COMMENT_NODE") 
    {
        # 處理註解
        $text = "<!--" . $node->getNodeValue() . "-->";
    }   
	else
	{
		print $node;
		print "\nFind some data no run !!! Call heaven !!!";
		exit;
	}
    return $text; 
}

# 處理子程序
sub parseChild
{
    my $node = shift;
    my $text = "";
    for my $kid ($node->getChildNodes) 
    {
        $text .= parseNode($kid);
    }
    return $text;    
}

# 處理文字
sub text_handler
{
    my $node = shift;
    my $text = $node->getNodeValue();   # 取得文字
    #$text =~ s/\n//g;   # 移除換行
	$text =~ s/&/&amp;/g;
	$text =~ s/</&lt;/g;
	return $text;     
}

################################
# 處理各種標記
################################

# <app>
sub tag_app
{
    my $node = shift;
	# 處理標記 <tag>
    my $tag_name = $node->getNodeName();
	# 處理屬性 a="x"
	my $attr_text = node_get_attr_text($node); 
    # 處理內容
    my $child_text = parseChild($node);
	# 處理標記結束 </tag>
	my $text = get_full_tag($tag_name,$attr_text,$child_text);

	# CBETA 新增的 app 加上 note
	# <app><lem resp="xxxx" wit="【CBETA】【麗】">Ａ<note type="cf1">xxxx</note></lem><rdg wit="【大】">Ｂ</rdg></app>
	# 轉成：
	# <note n="xxxxxxx" resp="xxxx" type="add">Ａ【CB】【麗-CB】，Ｂ【大】</note>
	# <app n="xxxxxxx"><lem resp="xxxx" wit="【CB】【麗-CB】">Ａ<note type="cf1">xxxx</note></lem><rdg wit="【大】">Ｂ</rdg></app>

	# 例 : T01n0026.xml
	# <lb n="0424b03" ed="T"/>謂住岸梵志。此七水喻人，我略說也。如上<app><lem resp="CBETA.maha CBETA.say" wit="【CBETA】【麗】">所<note type="cf1">KI17n0648_p1029c06</note><note type="cf2">T01n0026_p0422a13</note></lem><rdg wit="【大】"><space quantity="0"/></rdg></app>

	if($text =~ /<app>/)
	{
		my $old_text = $text;
	
		$text =~ s/\n//g;
		$text =~ s/(<app>.*?<\/app>)/AppAddNote($1)/e;

		print LOG2 "$lb_num : $old_text\n";
		print LOG2 "$lb_num : $text\n\n";
	}
	
	my $tmptext = $text;
	$tmptext =~ s/<note.*?<\/note>//g;
	$tmptext =~ s/<!\-\-.*?\-\->//g;
	if($tmptext =~ /\[[\d＊]+\]/)
	{
		print LOG4 "$lb_num : $text\n\n";
	}

    return $text;
}

# <choice>
sub tag_choice
{
    my $node = shift;
	# 處理標記 <tag>
    my $tag_name = $node->getNodeName();
	# 處理屬性 a="x"
	my $attr_text = node_get_attr_text($node); 
    # 處理內容
    my $child_text = parseChild($node);
	# 處理標記結束 </tag>
	my $text = get_full_tag($tag_name,$attr_text,$child_text);

	# ●CBETA 新增的 choice 轉成 note + app
	# <choice cb:resp="xxxx"><corr>Ａ</corr><sic>Ｂ</sic></choice>
	# 轉成：
	# <note n="xxxxxxx" resp="xxxx" type="add">Ａ【CB】，Ｂ【大】</note>
	# <app n="xxxxxxx"><lem wit="【CB】" resp="xxxx">Ａ</lem><rdg wit="【大】">Ｂ</rdg></app>

	# 例 : T01n0026.xml
	# <lb n="0425b21" ed="T"/>絞勒其<anchor xml:id="fxT01p0425b01"/><choice cb:resp="CBETA.maha CBETA.pan"><corr>𨄔</corr><sic>摶</sic></choice>斷皮，斷皮已斷肉，斷肉已斷

	if($text =~ /(<choice cb:resp=".*?">.*?<\/choice>)/)
	{
		my $old_text = $text;
	
		$text =~ s/\n//g;
		$text =~ s/(<choice.*?<\/choice>)/Choice2Note($1)/e;

		print LOG3 "$lb_num : $old_text\n";
		print LOG3 "$lb_num : $text\n\n";		
	}
	
	my $tmptext = $text;
	$tmptext =~ s/<note.*?<\/note>//g;
	$tmptext =~ s/<!\-\-.*?\-\->//g;
	if($tmptext =~ /\[[\d＊]+\]/)
	{
		print LOG4 "$lb_num : $text\n\n";
	}
    return $text;
}

# <lb n="0001a01" ed="T"/>
sub tag_lb
{
    my $node = shift;
	$lb_num = node_get_attr($node,"n");
	$lb_serial = 0;
    return tag_default($node);
}

sub tag_note
{
    my $node = shift;
	# 處理標記 <tag>
    my $tag_name = $node->getNodeName();
	# 處理屬性 a="x"
	my $attr_text = node_get_attr_text($node); 
	
	#  <note resp="xxxx">ＡＢＣＤＥ</note>
	#  轉成：
	#  <note n="xxxxxxx" resp="xxxx" type="add">ＡＢＣＤＥ</note>

	my $old_attr_text = "";
	if($node->getAttributes->getLength == 1 && $attr_text =~ / resp=/)
	{
		my $id = $lb_num . get_lb_serial();
		$old_attr_text = $attr_text;
		$attr_text = " n=\"$id\"" . $attr_text . " type=\"add\"";
	}
    
    # 處理內容
    my $child_text = parseChild($node);
	# 處理標記結束 </tag>
	my $text = get_full_tag($tag_name,$attr_text,$child_text);
	
	if($old_attr_text)	# 有這個, 表示要記錄
	{
		my $old_text = get_full_tag($tag_name,$old_attr_text,$child_text);
		
		print LOG1 "$lb_num : $old_text\n";
		print LOG1 "$lb_num : $text\n\n";
	}

    return $text;
}

# 處理預設標記
# <tag a="x">abc</tag>
sub tag_default
{
    my $node = shift;
	# 處理標記 <tag>
    my $tag_name = $node->getNodeName();
	# 處理屬性 a="x"
	my $attr_text = node_get_attr_text($node); 
    # 處理內容
    my $child_text = parseChild($node);
	# 處理標記結束 </tag>
	my $text = get_full_tag($tag_name,$attr_text,$child_text);
    return $text;
}

# node 取回指定屬性
# 用法 $attr_n = node_get_attr($node,"n");
sub node_get_attr
{
	my $node = shift;
	my $attr = shift;
	my $att_n = $node->getAttributeNode($attr);	# 取得屬性
    if($att_n)
    {
		my $n = $att_n->getValue();	# 取得屬性內容
		$n =~ s/&/&amp;/g;
		$n =~ s/</&lt;/g;
		$n =~ s/&amp;amp;/&amp;/g;
		$n =~ s/&amp;lt;/&lt;/g;
		return $n;
    }
	else
	{
		return "";
	}
}

# 組合成標準標記 <tag a="x">abc</tag>
sub get_full_tag 
{
	my $tag_name = shift;
	my $attr_text = shift;
	my $child_text = shift;
	my $text = "";
	
    if($child_text eq "")
	{
		$text = "<" . $tag_name . $attr_text . "/>";
	}
	else
	{
		$text = "<" . $tag_name . $attr_text . ">" . $child_text . "</$tag_name>";
	}
	return $text;
}

# 做出 node 的屬性字串, 如: a="x" b="y" c="z"
sub node_get_attr_text
{
	my $node = shift;
    my $attr_text = "";
	my $attr_map = $node->getAttributes;	# 取出所有屬性
	for my $tag_attr ($attr_map->getValues) # 取出單一屬性
	{
		my $attr_name = $tag_attr->getName;	# 取出單一屬性名稱
		my $attr_value = $tag_attr->getValue;	# 取出單一屬性內容
		$attr_value =~ s/&/&amp;/g;
		$attr_value =~ s/</&lt;/g;
		$attr_value =~ s/&amp;amp;/&amp;/g;
		$attr_value =~ s/&amp;lt;/&lt;/g;
		$attr_text .= " $attr_name=\"$attr_value\"";
	}
	return $attr_text;
}

# 傳回某行的流水序號, 在 lb 會自動歸零
sub get_lb_serial
{
	$lb_serial++;
	return sprintf("%02d",$lb_serial);
}

# <app>..</app> 變成 <note>..</note><app ..>..</app>
sub AppAddNote
{
	local $_ = shift;

	s/【CBETA】/【CB】/g;
	s/【麗】/【麗-CB】/g;
	s/【磧砂】/【磧砂-CB】/g;
	s/【嘉興】/【嘉興-CB】/g;
	s/【北藏】/【北藏-CB】/g;
	s/【龍】/【龍-CB】/g;

	my $lem = "";
	my $lem_wit = "";
	my $lem_word = "";
	my $rdg = "";
	my $rdg_level = 0;	# rdg 有幾層?
	my @rdg = ();		# 各層 rdg
	my @rdg_wit = ();
	my @rdg_word = ();
	my $note_text = "";	# note 的內容

	if(/(<lem[ >].*?<\/lem>)/)
	{
		$lem = $1;
		if($lem =~ /wit="(.*?)"/)
		{
			$lem_wit = $1;
		}
		$lem_word = $lem;
		$lem_word =~ s/<lem.*?>//;
		$lem_word =~ s/<\/lem>//;
		$lem_word =~ s/<note type="cf.*?<\/note>//g;
	}
	if(/(<rdg[ >].*<\/rdg>)/)
	{
		$rdg = $1;

		# 也許有多層 rdg
		
		while($rdg =~ /(<rdg[ >].*?<\/rdg>)/)
		{
			$rdg =~ s/(<rdg[ >].*?<\/rdg>)//;
			$rdg[$rdg_level] = $1;
			my $tmp = $rdg[$rdg_level];
			my $wit = "";
			if($tmp =~ /wit="(.*?)"/)
			{
				$wit = $1;
			}
			$tmp =~ s/<rdg.*?>//;
			$tmp =~ s/<\/rdg>//;
			$tmp =~ s/<note type="cf.*?<\/note>//g;

			if($tmp eq "") { $tmp = "［－］";}
			if($tmp eq "<space quantity=\"0\"/>") { $tmp = "［－］";}

			# 看看這一組有沒有在之前的版本出現過, 
			# 例如二版都是 A : <rdg wit=宋>A</rdg><rdg wit=明>A</rdg>
			my $find_in_old = 0;
			if($lem_word eq $tmp)
			{
				# rdg 版本內容和 lem 一樣
				$lem_wit .= $wit;
				$find_in_old = 1;
			}
			else
			{
				for(my $i=0; $i<$rdg_level; $i++)
				{				
					if($rdg_word[$i] eq $tmp)
					{
						$rdg_wit[$i] .= $wit;
						$find_in_old = 1;
						last;
					}
				}
			}
			if($find_in_old == 0)
			{
				$rdg_word[$rdg_level] = $tmp;
				$rdg_wit[$rdg_level] = $wit;
				$rdg_level++;
			}
		}
	}

	# 處理 <note> 標記的文字

	$lem_word = move_punc($lem_word);
	if($lem_word eq "")
	{
		$note_text .= "［－］";
	}
	elsif($lem_word eq "<space quantity=\"0\"/>")
	{
		$note_text .= "［－］";
	}
	else
	{
		$note_text .= $lem_word;
	}
	$note_text .= $lem_wit;

	for(my $i=0; $i<$rdg_level; $i++)
	{
		$note_text .= "，";
		my $rdg_word = move_punc($rdg_word[$i]);
		$note_text .= $rdg_word;
		$note_text .= $rdg_wit[$i];
	}

	# 組合最後結果
	# <note n="xxxxxxx" resp="xxxx" type="add">Ａ【CB】【麗-CB】，Ｂ【大】</note>
	# <app n="xxxxxxx"><lem resp="xxxx" wit="【CB】【麗-CB】">Ａ<note 

	my $newid = $lb_num . get_lb_serial();
	my $out = "<note n=\"" . $newid . "\" resp=\"CBETA\" type=\"add\">";
	$out .= $note_text . "</note>";

	s/<app>/<app n="$newid">/;

	$out .= $_;
	return $out;
}

# <choice>..</choice> 變成 <note>..</note><app ..>..</app>
sub Choice2Note
{
	local $_ = shift;

	my $resp = "";
	my $lem = "";
	my $lem_word = "";
	my $rdg = "";
	my $rdg_word = "";

	my $note_text = "";		# note 的內容

	if(/<choice cb:resp="(.*?)">/)
	{
		$resp = $1;
	}
	if(/<corr>(.*?)<\/corr>/)
	{
		$lem = $1;
		$lem_word = $lem;
		$lem_word =~ s/<note type="cf.*?<\/note>//g;
		$lem_word = move_punc($lem_word);
	}
	if(/<sic>(.*?)<\/sic>/)
	{
		$rdg = $1;
		$rdg_word = $rdg;
		$rdg_word =~ s/<note type="cf.*?<\/note>//g;
		$rdg_word = move_punc($rdg_word);
	}

	# 處理 <note> 標記的文字

	if($lem_word eq "")
	{
		$note_text .= "［－］";
	}
	elsif($lem_word eq "<space quantity=\"0\"/>")
	{
		$note_text .= "［－］";
	}
	else
	{
		$note_text .= $lem_word;
	}
	$note_text .= "【CB】，";

	if($rdg_word eq "")
	{
		$note_text .= "［－］";
	}
	elsif($rdg_word eq "<space quantity=\"0\"/>")
	{
		$note_text .= "［－］";
	}
	else
	{
		$note_text .= $rdg_word;
	}
	$note_text .= $bookver;	

	# 組合最後結果
	# <note n="xxxxxxx" resp="xxxx" type="add">Ａ【CB】，Ｂ【大】</note>
	# <app n="xxxxxxx"><lem wit="【CB】" resp="xxxx">Ａ</lem><rdg wit="【大】">Ｂ</rdg></app>

	my $newid = $lb_num . get_lb_serial();
	my $out = "<note n=\"" . $newid . "\" resp=\"CBETA\" type=\"add\">";
	$out .= $note_text . "</note>";

	$out .= "<app n=\"$newid\"><lem wit=\"【CB】\" resp=\"$resp\">$lem</lem><rdg wit=\"$bookver\">$rdg</rdg></app>";

	return $out;
}

sub move_punc
{
	local $_ = shift;

	s/。//g;
	s/，//g;
	s/、//g;
	s/；//g;
	s/：//g;
	s/「//g;
	s/」//g;
	s/『//g;
	s/』//g;
	s/（//g;
	s/）//g;
	s/？//g;
	s/！//g;
	s/— //g;
	s/… //g;
	s/《//g;
	s/》//g;
	s/〈//g;
	s/〉//g;
	s/．//g;
	s/　//g;

	return $_;
}