using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Xml;
using System.IO;

namespace setBumpmap
{
    public partial class Form1 : Form
    {
        FileInfo daeFile;
        XmlDocument daeDoc;
        XmlNamespaceManager nsMgr;
        String uri;


        public Form1()
        {
            InitializeComponent();

        }

        private void Form1_Load(object sender, EventArgs e)
        {
            string[] args = Environment.GetCommandLineArgs();
            
            try
            {
                //is the last parameter a dae File?
                if (args.Last<string>().ToLower().Contains(".dae") == true)
                {
                    //load it as FileInfo
                    loadDae(args.Last<string>());
                }
            }
            catch (Exception)
            {
                MessageBox.Show("error, no file specified");
            }

        }

        //shuld open a FileDialog!
        private void btn_dae_Click(object sender, EventArgs e)
        {
            OpenFileDialog openFile = new OpenFileDialog();
            openFile.Filter = "DAE|*.dae";
            openFile.ShowDialog();
            if (openFile.FileName != String.Empty && loadDae(openFile.FileName) == true)
            {
                groupBox_Textures.Enabled = true;
                groupBox_Textures2.Enabled = true;
            }
        }

        //shuld open a FileDialog!
        private void btn_bumpmap_Click(object sender, EventArgs e)
        {
            OpenFileDialog openFile = new OpenFileDialog();
            openFile.Filter = "JPEG|*.jpg|PNG|*.png|PSD|*.psd|TGA|*.tga|All Files|*.*";
            openFile.ShowDialog();

            if (openFile.FileName != String.Empty)
            {
                if (addTexture(daeDoc, new FileInfo(openFile.FileName), "bump") == true)
                {
                //saves the xmlFile
                daeDoc.Save(daeFile.FullName);
                richTextBox1.Text += "success!!!";
                }
                else
                {
                richTextBox1.Text += "failed, file unsaved!";
                }

            }

        }

        private void btn_dae_DragDrop(object sender, DragEventArgs e)
        {
            string[] files = (string[])e.Data.GetData(DataFormats.FileDrop);

            picBoxAmbient.Image = null;
            picBoxBump.Image = null;
            picBoxDiff.Image = null;
            picBoxReflec.Image = null;
            picBoxSpec.Image = null;
            picBoxTrans.Image = null;

            if (loadDae(files[0]) == true)
            {
                groupBox_Textures.Enabled = true;
                groupBox_Textures2.Enabled = true;
                loadImages();
            }
        }

        private void btn_dae_DragEnter(object sender, DragEventArgs e)
        {
            if (e.Data.GetDataPresent(DataFormats.FileDrop, false))
            {
                //a bool that allows dropping
                bool dropable = true;

                //is it a dae File?
                string[] files = (string[])e.Data.GetData(DataFormats.FileDrop);
                

                foreach (string file in files)
                {
                    if (file.ToLower().Contains(".dae") == false)
                        dropable = false;
                }

                if (dropable)
                {
                    //allow File
                    e.Effect = DragDropEffects.All;
                }
            }
        }
 
        private bool loadDae(string filePosition)
        {
            try
            {
                richTextBox1.Text += "loading file\n";
                daeFile = new FileInfo(filePosition);
            }
            catch (FileNotFoundException e)
            {

                richTextBox1.Text += e.Message;
                return false;
            }

            try
            {   
                // Create an XML document instance.
                // The same instance of DOM is used through out this code; this 
                // may or may not be the actual case.
                daeDoc = new XmlDocument();


                // Load the XML data from a file.
                // This code assumes that the XML file is in the same folder.
                daeDoc.Load(daeFile.FullName);

                XmlElement root = daeDoc.DocumentElement;
                //test
                XmlNodeList elementList = root.GetElementsByTagName("phong");

                //generates a Namespeace Manager
                nsMgr = new XmlNamespaceManager(daeDoc.NameTable);

                //adds the documents Namespace
                nsMgr.AddNamespace("ns", daeDoc.DocumentElement.NamespaceURI);
                uri = daeDoc.DocumentElement.NamespaceURI;


            }
            catch (XmlException xmlEx)   // Handle the XML exceptions here.   
            {
                richTextBox1.Text += (xmlEx.Message);
                return false;
            }
            catch (Exception ex)         // Handle the generic exceptions here.
            {
                richTextBox1.Text += (ex.Message);
                return false;
            }
            finally
            {
                // Finalize here.
                richTextBox1.Text += "file loaded\n";
            }
            return true;
        }

        private bool loadImages()
        {
            try
            {

            //searches for image entries
            XmlNodeList imageList = daeDoc.SelectNodes("/ns:COLLADA/ns:library_images/ns:image", nsMgr);
            XmlNodeList imageBaseList = daeDoc.SelectNodes("/ns:COLLADA/ns:library_effects/ns:effect/ns:profile_COMMON/ns:technique/ns:phong/ns:*[ns:texture]", nsMgr);

            foreach (XmlNode node in imageList)
                {
                    string texturetype = node.Attributes.GetNamedItem("id").Value;

                    foreach (XmlNode texturenode in imageBaseList)
                    {
                        if (texturetype == texturenode.FirstChild.Attributes.GetNamedItem("texture").Value)
                        {
                            string path = node.FirstChild.FirstChild.Value.Substring(7);

                            switch (texturenode.Name)
                            {
                                case "diffuse":
                                    if (Path.IsPathRooted(path) == false)
                                        picBoxDiff.Load(Path.Combine(daeFile.DirectoryName, @"..\..\" + path));
                                    else
                                        picBoxDiff.Load(path);
                                    break;
                                case "ambient":
                                    if (Path.IsPathRooted(path) == false)
                                        picBoxAmbient.Load(Path.Combine(daeFile.DirectoryName, @"..\..\" + path));
                                    else
                                        picBoxAmbient.Load(path);
                                    break;
                                case "bump":
                                    if (Path.IsPathRooted(path) == false)
                                        picBoxBump.Load(Path.Combine(daeFile.DirectoryName, @"..\..\" + path));
                                    else
                                        picBoxBump.Load(path);
                                    break;
                                case "specular":
                                    if (Path.IsPathRooted(path) == false)
                                        picBoxSpec.Load(Path.Combine(daeFile.DirectoryName, @"..\..\" + path));
                                    else
                                        picBoxSpec.Load(path);
                                    break;
                                case "reflective":
                                    if (Path.IsPathRooted(path) == false)
                                        picBoxReflec.Load(Path.Combine(daeFile.DirectoryName, @"..\..\" + path));
                                    else
                                        picBoxReflec.Load(path);
                                    break;
                                default:
                                    break;
                            }
                        }
                    }

                }
            }
            catch (Exception ex)
            {

                richTextBox1.Text += ex.Message + "\n";
                return false;
            }

            return true;
           
        }

        private bool addTexture(XmlDocument daeDoc, FileInfo textureFile, String textureChannel)
        {
            XmlElement root = daeDoc.DocumentElement;

            try
            {

                //generates a Namespeace Manager
                XmlNamespaceManager nsMgr = new XmlNamespaceManager(daeDoc.NameTable);

                //adds the documents Namespace
                nsMgr.AddNamespace("ns", daeDoc.DocumentElement.NamespaceURI);
                String uri = daeDoc.DocumentElement.NamespaceURI;


                //problem, existiert nicht beim TEAPOT!
                 XmlNode specular = root.SelectSingleNode("/ns:COLLADA/ns:library_effects", nsMgr);
                richTextBox1.Text += specular.Name + "\n";


                //link
                XmlNode phongNode = root.SelectSingleNode("/ns:COLLADA/ns:library_effects/ns:effect/ns:profile_COMMON/ns:technique/ns:phong", nsMgr);

                //check if the bumpmap is already included
                XmlNode channelNode = phongNode.SelectSingleNode("//ns:" + textureChannel, nsMgr);

                if (channelNode != null)
                {
                    richTextBox1.Text += textureChannel + " found! Replacing it!\n";
                    //set the new Value to Bumpmap
                    channelNode.FirstChild.Attributes.Item(0).Value = textureChannel + "map";
                    daeDoc.Save(daeFile.FullName);

                }
                else
                {
                    richTextBox1.Text += "no " + textureChannel + " found. Adding new one!\n";

                    XmlText xmlText;

                    //creates a node named bump
                    channelNode = daeDoc.CreateElement(textureChannel, uri);
                    //adds the bump child node to phong
                    phongNode.AppendChild(channelNode);

                    XmlNode textureNode = daeDoc.CreateElement("texture", uri);

                    //creates the Texture Attribute
                    XmlAttribute textureAtt = daeDoc.CreateAttribute("texture");
                    textureAtt.Value = textureChannel + "map";

                    //creates the textcoord Attribute
                    XmlAttribute texcoordAtt = daeDoc.CreateAttribute("texcoord");
                    texcoordAtt.Value = "CHANNEL0";

                    //adds the attribute to the TextureNode
                    textureNode.Attributes.Prepend(textureAtt);
                    textureNode.Attributes.InsertAfter(texcoordAtt, textureAtt);

                    //adds the TextureNode as Childnode to the Bumpmap
                    channelNode.AppendChild(textureNode);

                    XmlNode extraNode = daeDoc.CreateElement("extra", uri);

                    //adds the extra Node as Childnode to the Texturenode
                    textureNode.AppendChild(extraNode);

                    //creates a new Node
                    XmlNode techniqueNode = daeDoc.CreateElement("technique", uri);

                    //create its Attribute
                    XmlAttribute profileAtt = daeDoc.CreateAttribute("profile");
                    profileAtt.Value = "MAYA";
                    //adds its Attribute
                    techniqueNode.Attributes.Prepend(profileAtt);

                    //adds it to extra
                    extraNode.AppendChild(techniqueNode);

                    //Creates the three nodes in technique
                    XmlNode warpUNode = daeDoc.CreateElement("warpU", uri);
                    xmlText = daeDoc.CreateTextNode("TRUE");
                    warpUNode.AppendChild(xmlText);

                    XmlAttribute sid1Att = daeDoc.CreateAttribute("sid");
                    warpUNode.Attributes.Prepend(sid1Att);
                    sid1Att.Value = "warpU0";

                    XmlNode warpVNode = daeDoc.CreateElement("warpV", uri);
                    xmlText = daeDoc.CreateTextNode("TRUE");
                    warpVNode.AppendChild(xmlText);
                    XmlAttribute sid2Att = daeDoc.CreateAttribute("sid");
                    warpVNode.Attributes.Prepend(sid2Att);
                    sid2Att.Value = "warpV0";

                    XmlNode blend_modeNode = daeDoc.CreateElement("blend_mode", uri);
                    xmlText = daeDoc.CreateTextNode("ADD");
                    blend_modeNode.AppendChild(xmlText);

                    //adds the three nodes to the technique node
                    techniqueNode.AppendChild(warpUNode);
                    techniqueNode.AppendChild(warpVNode);
                    techniqueNode.AppendChild(blend_modeNode);
                }

                try
                {

                    //finds a ImageNode in the Libary
                    XmlNode imageNode = root.SelectSingleNode("/ns:COLLADA/ns:library_images/ns:image", nsMgr);


                    if (imageNode != null)
                    {
                        //Libary_Images exist so lets copy a image node and paste it in the same node!
                        XmlNode bumpImageNode = imageNode.Clone();
                        root.SelectSingleNode("/ns:COLLADA/ns:library_images", nsMgr).AppendChild(bumpImageNode);
                        bumpImageNode.Attributes.Item(0).Value = textureChannel + "map";
                        bumpImageNode.ChildNodes.Item(0).ChildNodes.Item(0).Value = "file://" + textureFile.FullName;

                    }
                    else
                    {
                        //library_images needs to be created 
                        imageNode = root.SelectSingleNode("ns:COLLADA/ns:assert", nsMgr);

                        XmlNode imageTextureNode = daeDoc.CreateElement("library_images", uri);
                        root.InsertAfter(imageTextureNode, imageNode);

                        XmlNode libaryImageNode = daeDoc.CreateElement("image", uri);
                        imageNode.PrependChild(libaryImageNode);

                        XmlNode init_fromNode = daeDoc.CreateElement("init_from", uri);
                        libaryImageNode.PrependChild(init_fromNode);

                        XmlText init_fromText = daeDoc.CreateTextNode("file://" + textureFile.FullName);
                    }                        

                }
                catch (Exception e)
                {

                    MessageBox.Show("no Diffusemap defined!" + e.Message + "\n", "Error!", MessageBoxButtons.OK);
                }
 

                return true;
            }
            catch (Exception e)
            {

                richTextBox1.Text += e.Message;
                return false;
            }


        }

        #region Texture DragEnter

        private void TextureDragEnter(object sender, DragEventArgs e)
        {
            if (e.Data.GetDataPresent(DataFormats.FileDrop, false))
            {
                //a bool that allows dropping
                bool dropable = false;

                //is it a dae File?
                string[] files = (string[])e.Data.GetData(DataFormats.FileDrop);

                //checks every single file
                foreach (string file in files)
                {
                    //imagecheck
                    if (
                        file.ToLower().Contains(".jpg") ||
                        file.ToLower().Contains(".png") ||
                        file.ToLower().Contains(".tga") ||
                        file.ToLower().Contains(".psd") ||
                        file.ToLower().Contains(".bmp")
                        )
                        dropable = true;
                }

                if (dropable)
                {
                    //allow File
                    e.Effect = DragDropEffects.All;
                }
            }
        }

        private void btn_diffusemap_DragEnter(object sender, DragEventArgs e)
        {
            TextureDragEnter(sender, e);
        }

        private void btn_transparentmap_DragEnter(object sender, DragEventArgs e)
        {
            TextureDragEnter(sender, e);
        }

        private void btn_specularmap_DragEnter(object sender, DragEventArgs e)
        {
            TextureDragEnter(sender, e);
        }

        private void btn_ambientmap_DragEnter(object sender, DragEventArgs e)
        {
            TextureDragEnter(sender, e);
        }

        private void btn_reflectivemap_DragEnter(object sender, DragEventArgs e)
        {
            TextureDragEnter(sender, e);
        }   
     
        private void btn_bumpmap_DragEnter(object sender, DragEventArgs e)
        {
            TextureDragEnter(sender, e);
        }

        #endregion

        #region DragDrop

        private void btn_diffusemap_DragDrop(object sender, DragEventArgs e)
        {
            string[] files = (string[])e.Data.GetData(DataFormats.FileDrop);

            if (addTexture(daeDoc, new FileInfo(files[0]), "diffuse") == true)
            {
                loadImages();
                //saves the xmlFile
                daeDoc.Save(daeFile.FullName);
                richTextBox1.Text += "success!!!";
            }
            else
            {
                richTextBox1.Text += "failed, file unsaved!";
            }
        }

        private void btn_transparentmap_DragDrop(object sender, DragEventArgs e)
        {
            string[] files = (string[])e.Data.GetData(DataFormats.FileDrop);

            if (addTexture(daeDoc, new FileInfo(files[0]), "transparent") == true)
            {
                loadImages();
                //saves the xmlFile
                daeDoc.Save(daeFile.FullName);
                richTextBox1.Text += "success!!!";
            }
            else
            {
                richTextBox1.Text += "failed, file unsaved!";
            }
        }

        private void btn_specularmap_DragDrop(object sender, DragEventArgs e)
        {
            string[] files = (string[])e.Data.GetData(DataFormats.FileDrop);

            if (addTexture(daeDoc, new FileInfo(files[0]), "specular") == true)
            {
                loadImages();
                //saves the xmlFile
                daeDoc.Save(daeFile.FullName);
                richTextBox1.Text += "success!!!";
            }
            else
            {
                richTextBox1.Text += "failed, file unsaved!";
            }
        }

        private void btn_ambientmap_DragDrop(object sender, DragEventArgs e)
        {
            string[] files = (string[])e.Data.GetData(DataFormats.FileDrop);

            if (addTexture(daeDoc, new FileInfo(files[0]), "ambient") == true)
            {
                loadImages();
                //saves the xmlFile
                daeDoc.Save(daeFile.FullName);
                richTextBox1.Text += "success!!!";
            }
            else
            {
                richTextBox1.Text += "failed, file unsaved!";
            }
        }

        private void btn_reflectivemap_DragDrop(object sender, DragEventArgs e)
        {
            string[] files = (string[])e.Data.GetData(DataFormats.FileDrop);

            if (addTexture(daeDoc, new FileInfo(files[0]), "reflective") == true)
            {
                loadImages();
                //saves the xmlFile
                daeDoc.Save(daeFile.FullName);
                richTextBox1.Text += "success!!!";
            }
            else
            {
                richTextBox1.Text += "failed, file unsaved!";
            }
        } 
        
        private void btn_bumpmap_DragDrop(object sender, DragEventArgs e)
        {
            string[] files = (string[])e.Data.GetData(DataFormats.FileDrop);

            if ( addTexture(daeDoc, new FileInfo(files[0]), "bump") == true)
            {
                loadImages();
                //saves the xmlFile
                daeDoc.Save(daeFile.FullName);
                richTextBox1.Text += "success!!!";
            }
            else
            {
                richTextBox1.Text += "failed, file unsaved!";
            }



        }

        #endregion
    }
}
