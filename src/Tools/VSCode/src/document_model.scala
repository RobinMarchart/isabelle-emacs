/*  Title:      Tools/VSCode/src/document_model.scala
    Author:     Makarius

Document model for line-oriented text.
*/

package isabelle.vscode


import isabelle._

import java.io.{File => JFile}


object Document_Model
{
  def init(session: Session, node_name: Document.Node.Name): Document_Model =
  {
    val resources = session.resources.asInstanceOf[VSCode_Resources]
    val doc = Line.Document("", resources.text_length)
    Document_Model(session, node_name, doc)
  }
}

sealed case class Document_Model(
  session: Session,
  node_name: Document.Node.Name,
  doc: Line.Document,
  external_file: Boolean = false,
  node_required: Boolean = false,
  last_perspective: Document.Node.Perspective_Text = Document.Node.no_perspective_text,
  pending_edits: List[Text.Edit] = Nil,
  published_diagnostics: List[Text.Info[Command.Results]] = Nil) extends Document.Model
{
  /* external file */

  def external(b: Boolean): Document_Model = copy(external_file = b)

  def node_visible: Boolean = !external_file


  /* header */

  def node_header: Document.Node.Header =
    resources.special_header(node_name) getOrElse
    {
      if (is_theory)
        resources.check_thy_reader("", node_name, Scan.char_reader(doc.text))
      else Document.Node.no_header
    }


  /* perspective */

  def node_perspective(doc_blobs: Document.Blobs): (Boolean, Document.Node.Perspective_Text) =
  {
    if (is_theory) {
      val snapshot = this.snapshot()

      val text_perspective =
        if (node_visible || snapshot.commands_loading_ranges(resources.visible_node(_)).nonEmpty)
          Text.Perspective.full
        else Text.Perspective.empty

      (snapshot.node.load_commands_changed(doc_blobs),
        Document.Node.Perspective(node_required, text_perspective, Document.Node.Overlays.empty))
    }
    else (false, Document.Node.no_perspective_text)
  }


  /* blob */

  def get_blob: Option[Document.Blob] =
    if (is_theory) None
    else Some((Document.Blob(doc.bytes, doc.chunk, pending_edits.nonEmpty)))


  /* edits */

  def update_text(text: String): Option[Document_Model] =
  {
    val old_text = doc.text
    val new_text = Line.normalize(text)
    Text.Edit.replace(0, old_text, new_text) match {
      case Nil => None
      case edits =>
        val doc1 = Line.Document(new_text, doc.text_length)
        val pending_edits1 = pending_edits ::: edits
        Some(copy(doc = doc1, pending_edits = pending_edits1))
    }
  }

  def flush_edits(doc_blobs: Document.Blobs): Option[(List[Document.Edit_Text], Document_Model)] =
  {
    val (reparse, perspective) = node_perspective(doc_blobs)
    if (reparse || pending_edits.nonEmpty || last_perspective != perspective) {
      val edits: List[Document.Edit_Text] =
        get_blob match {
          case None =>
            List(session.header_edit(node_name, node_header),
              node_name -> Document.Node.Edits(pending_edits),
              node_name -> perspective)
          case Some(blob) =>
            List(node_name -> Document.Node.Blob(blob),
              node_name -> Document.Node.Edits(pending_edits))
        }
      Some((edits, copy(pending_edits = Nil, last_perspective = perspective)))
    }
    else None
  }


  /* diagnostics */

  def publish_diagnostics(rendering: VSCode_Rendering)
    : Option[(List[Text.Info[Command.Results]], Document_Model)] =
  {
    val diagnostics = rendering.diagnostics
    if (diagnostics == published_diagnostics) None
    else Some(diagnostics, copy(published_diagnostics = diagnostics))
  }


  /* prover session */

  def resources: VSCode_Resources = session.resources.asInstanceOf[VSCode_Resources]

  def is_stable: Boolean = pending_edits.isEmpty
  def snapshot(): Document.Snapshot = session.snapshot(node_name, pending_edits)

  def rendering(): VSCode_Rendering = new VSCode_Rendering(this, snapshot(), resources)
}
