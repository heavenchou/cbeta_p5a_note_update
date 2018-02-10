##########################################################################
#
# 把 印順導師全集中 note/orig 中有 choice 標記, 改成二組 orig 和 mod
# <note n="0142012" resp="釋印順" type="orig">...<choice>...
# 改成
# <note n="0142012" resp="釋印順" type="orig">.... 只取 sic 的內容
# <note n="0142012" ​​resp="正聞出版社" type="mod">...... 只取 corr 的內容
#
##########################################################################

use utf8;
use Cwd;
use strict;
use XML::DOM;
my $parser = new XML::DOM::Parser;

my $SourcePath = "C:/cbwork/xml-p5a/Y/Y37";			# 初始目錄, 最後不用加斜線 /
my $OutputPath = "c:/temp/xml-p5a-new/Y/Y37";		# 目地初始目錄, 如果有需要的話. 最後不用加斜線 /
my $log_file1 = "7_Y_orig_mod_log.txt";		# log 檔 , 記錄 note in note

my $MakeOutputPath = 1;		# 1 : 產生對應的輸出目錄
my $IsIncludeSubDir = 1;	# 1 : 包含子目錄 0: 不含子目錄
my $FilePattern = "*.xml";	# 要找的檔案類型

my $lb_num = "";

open LOG1, ">:utf8", $log_file1;
SearchDir($SourcePath, $OutputPath);
close LOG1;

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
	print LOG1 $file . "=============== \n";

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
        if($tag_name eq "lb") { $text = tag_lb($node); }
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

# <lb n="0001a01" ed="T"/>
sub tag_lb
{
    my $node = shift;
	$lb_num = node_get_attr($node,"n");
    return tag_default($node);
}

sub tag_note
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

	# 把 印順導師全集中 note/orig 中有 choice 標記, 改成二組 orig 和 mod
	# <note n="0142012" resp="釋印順" type="orig">...<choice>...
	# 改成
	# <note n="0142012" resp="釋印順" type="orig">.... 只取 sic 的內容
	# <note n="0142012" ​​resp="正聞出版社" type="mod">...... 只取 corr 的內容

	if($attr_text =~ /type="orig"/ && $text =~ /<choice[^>]*>/)
	{
		my $origtext = $text;
		my $modtext = $text;

		$origtext =~ s/<choice[^>]*>//g;
		$origtext =~ s/<\/choice>//g;
		$origtext =~ s/<corr[^>]*>.*?<\/corr>//gs;
		$origtext =~ s/<sic[^>]*>//g;
		$origtext =~ s/<\/sic>//g;
		$origtext =~ s/<corr[^>]*\/>//g;
		$origtext =~ s/<sic[^>]*\/>//g;

		$origtext =~ s/<reg[^>]*>.*?<\/reg>//gs;
		$origtext =~ s/<orig[^>]*>//g;
		$origtext =~ s/<\/orig>//g;
		$origtext =~ s/<reg[^>]*\/>//g;
		$origtext =~ s/<orig[^>]*\/>//g;

		$modtext =~ s/<choice[^>]*>//g;
		$modtext =~ s/<\/choice>//g;
		$modtext =~ s/<corr[^>]*>//g;
		$modtext =~ s/<\/corr>//g;
		$modtext =~ s/<sic[^>]*>.*?<\/sic>//gs;
		$modtext =~ s/<corr[^>]*\/>//g;
		$modtext =~ s/<sic[^>]*\/>//g;

		$modtext =~ s/<reg[^>]*>//g;
		$modtext =~ s/<\/reg>//g;
		$modtext =~ s/<orig[^>]*>.*?<\/orig>//gs;
		$modtext =~ s/<reg[^>]*\/>//g;
		$modtext =~ s/<orig[^>]*\/>//g;

		$modtext =~ s/resp="釋印順"/resp="正聞出版社"/;
		$modtext =~ s/type="orig"/type="mod"/;

		print LOG1 "$lb_num : $text\n";
		print LOG1 "$lb_num : $origtext$modtext\n\n";

		$text = $origtext . $modtext;
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
