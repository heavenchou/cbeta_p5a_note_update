##########################################################################
#
# 把 CBETA 舊校勘修訂成新的校勘
# 列出 <app>, <choice> 在 <note> 
#
##########################################################################

use utf8;
use Cwd;
use strict;
use XML::DOM;
my $parser = new XML::DOM::Parser;

my $SourcePath = "c:/cbwork/xml-p5a/T/";			# 初始目錄, 最後不用加斜線 /
my $OutputPath = "c:/temp/xml-p5a-new/T/";		# 目地初始目錄, 如果有需要的話. 最後不用加斜線 /
$SourcePath = "c:/temp/xml-p5a-new/T/";			# 初始目錄, 最後不用加斜線 /
$OutputPath = "c:/temp/xml-p5a-new/TT/";		# 目地初始目錄, 如果有需要的話. 最後不用加斜線 /
my $log_file = "app_choice_in_note_log.txt";		# log 檔 , 記錄 note in note
#my $log1_file = "note_in_note_log1.txt";	# log 檔 , 記錄 <note resp> 變成 type=add

my $MakeOutputPath = 1;		# 1 : 產生對應的輸出目錄
my $IsIncludeSubDir = 1;	# 1 : 包含子目錄 0: 不含子目錄
my $FilePattern = "*.xml";		# 要找的檔案類型

my $lb_num;				# 行首頁欄行
my $note_level = 0;		# note 層次
my $note_in_note = 0;	# 用來判斷有沒有 note 包 note
my $lb_serial = 0;		# 每一行的序號
my $in_note_mod = 0;	# 判斷是否在 note/mod 中

open LOG, ">:utf8", $log_file;
SearchDir($SourcePath, $OutputPath);
close LOG;

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
	
	#### 要做的事

	print $file . "\n";
	print LOG $file . "=============== \n";
	#print LOG1 $file . "=============== \n";

	my $text = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
	$text .= ParserXML($file);

	#open OUT, ">:utf8", $outfile;
	#print OUT $text;
	#close OUT;
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
        # 處理文字
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
    return $text;     
}

################################
# 處理各種標記
################################

# 處理 xx 標記

# <xxx>abc</xxx>
sub tag_app
{
    my $node = shift;
    my $text = "";
	
	# 處理標記 <xxx>

    my $tag_name = $node->getNodeName();

	# 處理屬性

    my $attr_text = "";
	my $attr_map = $node->getAttributes;	# 取出所有屬性
	my $attr_name = "";	                    # 單一屬性名稱
	my $attr_value = "";	                # 單一屬性內容
	for my $tag_attr ($attr_map->getValues) # 取出單一屬性
	{
		$attr_name = $tag_attr->getName;	# 取出單一屬性名稱
		$attr_value = $tag_attr->getValue;	# 取出單一屬性內容
		$attr_text .= " $attr_name=\"$attr_value\"";
	}
    
    # 處理內容 abc

    my $child_text = parseChild($node);

	# 處理標記結束 </xxx>

    if($child_text eq "")
	{
		$text = "<" . $tag_name . $attr_text . "/>";
	}
	else
	{
		$text = "<" . $tag_name . $attr_text . ">$child_text</$tag_name>";
	}

	if($note_level > 0)
	{
		$note_in_note = 1;	# 通知有二層 note 了
	}

    return $text;
}

# <xxx>abc</xxx>
sub tag_choice
{
    my $node = shift;
    my $text = "";
	
	# 處理標記 <xxx>

    my $tag_name = $node->getNodeName();

	# 處理屬性

    my $attr_text = "";
	my $attr_map = $node->getAttributes;	# 取出所有屬性
	my $attr_name = "";	                    # 單一屬性名稱
	my $attr_value = "";	                # 單一屬性內容
	for my $tag_attr ($attr_map->getValues) # 取出單一屬性
	{
		$attr_name = $tag_attr->getName;	# 取出單一屬性名稱
		$attr_value = $tag_attr->getValue;	# 取出單一屬性內容
		$attr_text .= " $attr_name=\"$attr_value\"";
	}
    
    # 處理內容 abc

    my $child_text = parseChild($node);

	# 處理標記結束 </xxx>

    if($child_text eq "")
	{
		$text = "<" . $tag_name . $attr_text . "/>";
	}
	else
	{
		$text = "<" . $tag_name . $attr_text . ">$child_text</$tag_name>";
	}

	if($note_level > 0)
	{
		$note_in_note = 1;	# 通知有二層 note 了
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
	my $note_type = "";
    my $text = "";
	
	# 處理標記 <xxx>

    my $tag_name = $node->getNodeName();

	# 處理屬性

	my $attr_text = "";
	my $note_attr_map = $node->getAttributes;	# 取出所有屬性
	my $attr_num = 0;
	my $attr_name = "";	# 取出單一屬性名稱
	my $attr_value = "";	# 取出單一屬性內容
	for my $note_attr ($note_attr_map->getValues) # 取出單一屬性
	{
		$attr_name = $note_attr->getName;	# 取出單一屬性名稱
		$attr_value = $note_attr->getValue;	# 取出單一屬性內容
		$attr_text .= " $attr_name=\"$attr_value\"";
		$attr_num++;
	}

	if($attr_text =~ /place="inline"/)
	{
		$note_type = "inline";
	}
	if($attr_text =~ /type="cf/)
	{
		$note_type = "cf";
	}

	if($note_type ne "inline")	# inline 這類的不列入統計
	{
		$note_level++;
	}
	
	#  <note resp="xxxx">ＡＢＣＤＥ</note>
	#  轉成：
	#  <note n="xxxxxxx" resp="xxxx" type="add">ＡＢＣＤＥ</note>
    # 處理內容 abc

    my $child_text = parseChild($node);

	# 處理標記結束 </xxx>

    if($child_text eq "")
	{
		$text = "<" . $tag_name . $attr_text . "/>";
	}
	else
	{
		$text = "<" . $tag_name . $attr_text . ">$child_text</$tag_name>";
	}

	# 判斷是第幾層 note
	if($note_type ne "inline")	# inline 這類的不列入統計
	{
		$note_level--;
	}
	
	if($note_level > 0)
	{
		$note_in_note = 1;	# 通知有二層 note 了
	}

	# 最上一層才要印 log
	if($note_in_note == 1 && $note_level == 0)
	{
		print LOG "$lb_num : app,choice,note in note\n";
		print LOG "$text\n\n";
		$note_in_note = 0;
	}

    return $text;
}


# 處理預設標記
# <xxx>abc</xxx>
sub tag_default
{
    my $node = shift;
    my $text = "";
	
	# 處理標記 <xxx>

    my $tag_name = $node->getNodeName();

	# 處理屬性

    my $attr_text = "";
	my $attr_map = $node->getAttributes;	# 取出所有屬性
	my $attr_name = "";	                    # 單一屬性名稱
	my $attr_value = "";	                # 單一屬性內容
	for my $tag_attr ($attr_map->getValues) # 取出單一屬性
	{
		$attr_name = $tag_attr->getName;	# 取出單一屬性名稱
		$attr_value = $tag_attr->getValue;	# 取出單一屬性內容
		$attr_text .= " $attr_name=\"$attr_value\"";
	}
    
    # 處理內容 abc

    my $child_text = parseChild($node);

	# 處理標記結束 </xxx>

    if($child_text eq "")
	{
		$text = "<" . $tag_name . $attr_text . "/>";
	}
	else
	{
		$text = "<" . $tag_name . $attr_text . ">$child_text</$tag_name>";
	}
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
		return $n;
    }
	else
	{
		return "";
	}
}