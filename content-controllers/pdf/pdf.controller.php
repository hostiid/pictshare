<?php 

class PdfController implements ContentController
{
    public const ctype = 'static';
    
    //returns all extensions registered by this type of content
    public function getRegisteredExtensions(){return array('pdf');}

    public function handleHash($hash,$url)
    {
        $path = getDataDir().DS.$hash.DS.$hash;

        if(in_array('raw',$url))
        {
            header('Content-Type: application/pdf');
            echo file_get_contents($path);
        }
        else if(in_array('download',$url))
        {
            if (file_exists($path)) {
                header('Content-Description: File Transfer');
                header('Content-Type: application/pdf');
                header('Content-Disposition: attachment; filename="'.basename($path).'"');
                header('Expires: 0');
                header('Cache-Control: must-revalidate');
                header('Pragma: public');
                header('Content-Length: ' . filesize($path));
                readfile($path);
                exit;
            }
        }
        else
            renderTemplate('pdf',array('hash'=>$hash,'url'=>implode('/',$url),'filesize'=>renderSize(filesize($path))));
    }

    public function handleUpload($tmpfile,$hash=false)
    {
        // Verify that the file is a PDF
        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mime = $finfo->file($tmpfile);
        
        if($mime !== 'application/pdf') {
            return array('status'=>'err','reason'=>'Only PDF files are accepted');
        }
        
        if($hash===false)
        {
            $hash = getNewHash('pdf',6);
        }
        else
        {
            if(!endswith($hash,'.pdf'))
                $hash.='.pdf';
            if(isExistingHash($hash))
                return array('status'=>'err','hash'=>$hash,'reason'=>'Custom hash already exists');
        }

        storeFile($tmpfile,$hash,true);
        
        return array('status'=>'ok','hash'=>$hash,'url'=>getURL().$hash);
    }

    function getTypeOfPdf($hash)
    {
        return file_get_contents(getDataDir().DS.$hash.DS.'type');
    }
}