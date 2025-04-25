// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: "linux libertine",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "linux libertine",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black or heading-decoration == "underline"
           or heading-background-color != none) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)

#show: doc => article(
  title: [The Sound of Libraries],
  subtitle: [ein Hörbild der Stadt Wien Büchereien],
  authors: (
    ( name: [Sarah Themel],
      affiliation: [Stadt Wien Büchereien],
      email: [] ),
    ),
  date: [2024-07-01],
  paper: "a4",
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)

Das Hörbild "The Sound of Libraries – ein Hörbild der Stadt Wien - Büchereien" entstand im Rahmen meiner Abschlussarbeit im "Lehrgang für hauptamtliche Bibliothekar\*innen" durch den BVÖ (Büchereiverband Österreich). Die Arbeit trägt den Titel #emph["Wir hören einander zu" - Lehrlingsprojekt "Hörbild". Partizipation als Notwendigkeit hin zur Demokratisierung von Arbeitsabläufen] (Themel, 2023).

Mit März 2020 und der Coronapandemie änderte sich mein ursprüngliches Vorhaben, ein Hörspiel mit einigen Lehrlingen der Stadt Wien - Büchereien zu erarbeiten, damit Schreibprozesse sowie audiomediale Arbeit zu begleiten und zu beobachten, mit dem Ergebnis einer tonalen Erzählung. Alltägliche Abläufe und die diesen immanenten Prozesshaftigkeiten – Arbeit, Kinderbetreuung, soziales Miteinander et cetera – verloren durch die Pandemie ihre beschworene Manifestation.

Ein großes Unglück? Oder unsere größte Chance? Ich entschloss mich, am Audioprojekt festzuhalten, inhaltlich jedoch ein Stimmungsbild der pandemischen Zeit darzustellen. Anhand eines mit den Lehrlingen gemeinsam ausgearbeiteten Fragebogens wurden mit 18 Mitarbeiter\*innen der Stadt Wien - Büchereien Interviews zum Thema "Corona" durchgeführt.

Aus der anfänglichen Idee eines "Klangnarrativs" entwickelte sich die Absicht, ein "Hörbild" entstehen zu lassen. Anhand der Interviews sollte rein akustisch-auditiv zur zunächst grob umrissenen Thematik "Die Stadt Wien - Büchereien in Zeiten von Corona" berichtet werden.

Im Zentrum des Projekts, auch schon des ursprünglichen, sollte die Ermöglichung von aktiver Teilhabe der Lehrlinge an einem künstlerischen, in die bibliothekarische Arbeit eingebetteten Prozesses stehen. Dadurch eröffnen sich für die Auszubildenden einerseits neue Blickwinkel im Umgang mit Kunst und Kultur, welche sie in ihre bibliothekarische Arbeit (zum Beispiel der Vermittlungsarbeit) mit einfließen lassen können. Andererseits bedeutet eine solche Teilhabe für diese Gruppe auch eine wichtige Voraussetzung für weitere, selbstbewusste Partizipation und Mitgestaltung von gesellschaftlichen und damit auch arbeitsrelevanten Prozessen.

In der gemeinsamen Arbeit mit den Lehrlingen (ein Schreibworkshop samt Vortrag eines Sounddesigners, das Erarbeiten der Fragen für die Interviews, der Durchführung einiger davon) und in Bezug auf das inhaltliche Anliegen der Aufnahmen, stellten sich mir einige weitere Fragen, zum Beispiel die nach der Bedeutung von Partizipation am Arbeitsplatz, demokratischen Arbeitsabläufen, kreativer Gemeinschaftlichkeit und der Notwendigkeit darum. Bibliotheken sind Orte der Information, Orte des Austauschs von Wissen – und in jedem Falle sind sie Orte der Begegnung. Wie wollen wir einander begegnen? Wäre die Bibliothek als Arbeitsplatz nicht ein wunderbarer Ort, um partizipative, demokratische, kreative Begegnungen zu erproben? Besonders Auszubildende sollten dabei "aus den Vollen" schöpfen können.

Öffentliche Büchereien verstehen sich schon längst nicht mehr nur als Orte des reinen Wissens- sowie Informationstransfers. "Der dritte Ort", Barrierefreiheit, Diversität – das sind nur ein paar Schlagworte, mit welchen sich die Bücherei neu identifiziert. Von der Leseförderung über den Maker Space hin zur gesellschaftlichen Teilhabe wird versucht, durch das eigene Angebot gesellschaftlich relevante Brücken zu bauen. Das ist nicht nur zeitgemäß, sondern eine wichtige und unbedingt zu erfüllende Aufgabe. Kreativ, mit viel Know-how ausgestattet, allgemeinen Bedürfnissen nachspürend, gesellschaftspolitische Trends erkennend, soll so der unter anderem auch kommunalen Funktion der öffentlichen Bücherei nachgekommen werden. Orte des Wohlfühlens, des Experiments, der kreativen Entfaltung, der Barrierefreiheit, ein Raum ohne Konsumzwang – werden immer mehr an Bedeutung gewinnen – so auch die öffentliche Bücherei.

== Warum das Thema "Corona"?: Von der Notwendigkeit einer gemeinsamen Aufarbeitung
<warum-das-thema-corona-von-der-notwendigkeit-einer-gemeinsamen-aufarbeitung>
Beinahe alles, was wir vor der Pandemie als Routine betrachteten, was unseren Alltag strukturierte und unser gewohntes Leben aufrechterhielt, war von einem Tag auf den anderen nicht mehr greifbar. Fast drei Jahre lang sahen wir uns in permanenter Alarmbereitschaft und damit im Ausnahmezustand. Später kamen noch dazu: ein Krieg mitten in Europa, Energieengpässe, Inflation et cetera, ein großes Fragezeichen, was unsere gemeinsame Zukunft betrifft.

Auch die Mitarbeiter\*innen der Stadt Wien - Büchereien sahen sich mit einer Aushebelung aller davor geltenden Praktiken konfrontiert. Alle Standorte (38 Zweigstellen) wurden geschlossen; der eigentlichen Funktion, dem Medienverleih, konnte nicht mehr nachgekommen werden. Relativ rasch wurde die Möglichkeit geschaffen, sogar kostenlos Literatur für (fast) alle über die virtuelle Bücherei zugänglich zu machen.

#quote(block: true)[
"Im ersten Lockdown im März 2020 hatten die Stadt Wien – Büchereien die Aufgabe, allen Wiener\*innern \[sic!\] ihre vielfältigen Angebote weiter zugänglich zu machen. Da ein Besuch der Standorte nicht möglich war, wurden diese in den virtuellen Raum verlagert." (Schneider & Volf, 2021, S. 473)
]

Dieses Angebot wurde auch zahlreich in Anspruch genommen:

#quote(block: true)[
"Mehr als 15.000 Menschen waren binnen weniger Tage eingeschrieben und konnten sich im Lockdown an den virtuellen Angeboten bedienen. Die Ausleihzahlen im April 2020 verdoppelten sich auf über 100.000, PressReader und Austria Kiosk erlebten die höchsten monatlichen Zugriffe bisher." (Schneider & Volf, 2021, S. 474)
]

Die Tatkraft vieler Mitarbeiter\*innen konnte dies trotz der Umstände ermöglichen. Auch gelang es, Veranstaltungen für alle Altersgruppen in den virtuellen Raum zu verlegen und zu etablieren, um so eine Nutzer\*innenbindung aufzubauen beziehungsweise bestehen zu lassen.

#quote(block: true)[
"Neue Nutzer\*innen konnten durch die systematische Bespielung weiterer vorhandener (YouTube, Podcasts) sowie neuer Kanäle (Instagram) gewonnen werden. Rasch riefen die Büchereien eine Schiene von Online-Lesungen unter dem Titel ‚Corona-Lesungen‛ ins Leben. Das Format bestand aus einer Mischung von Lesung und Interview mit österreichischen Autor\*innen. Um ein durchgängiges Programm (bis zu 3 Lesungen/Woche) zur Verfügung stellen zu können, wurde auf Initiative der Büchereien eine Kooperation mit Alter Schmiede, Österreichischer Gesellschaft für Literatur und dem Hauptverband des Buchhandels eingegangen. \[…\] den Zuspruch zu ihren bestehenden Online-Kanälen deutlich ausbauen und neue Kanäle etablieren. Gesamt verfügen die Social-Media-Kanäle der Büchereien mittlerweile über rund 85.000 Abonnent\*innen. Die Reichweite geht in die mehreren 100.000." (Schneider & Volf, 2021, S. 475)
]

Soweit eine Erfolgsgeschichte in krisenhaften Zeiten, welche sogar mit dem "Goldenen Staffelholz" der Stadt Wien ausgezeichnet wurde. Mit den schrittweisen Öffnungen (dazwischen immer wieder Lockdowns) musste immer wieder flexibel und angepasst auf die jeweiligen Bedürfnisse reagiert werden. Mit Click & Collect konnte einer teilweisen Öffnung begegnet werden: In beinahe allen Zweigstellen konnten Medien (bis zu 20 Stück) kostenlos vorbestellt und unter Einhaltung der jeweiligen Maßnahmen (zum Beispiel FFP2-Maske) abgeholt werden. Vom Waschen der Medien, Personenbeschränkungen und der Überprüfung dieser, vom verkürzten Aufenthalt der Leser\*innen in den Büchereien, vom Gesichtsschild, der Maske und den Handschuhen – dem temporären Verlust beinahe jeglicher kollegialen Begegnung – all dem wurde mit viel Flexibilität und Durchhaltevermögen durch die Mitarbeiter\*innen der Stadt Wien - Büchereien erfolgreich begegnet. Nach außen hin hat also alles geklappt, das Angebot konnte weitestgehend erfolgreich transportiert werden und fand damit auch entsprechenden Anklang.

Wie aber wirkte und wirkt diese pandemische Krise mit all ihren Effekten nach innen hinein? Wie ging und geht es den Mitarbeiter\*innen in dieser unsicheren Zeit? Was bedeutete diese Zeit für Mitarbeiter\*innen mit Kindern, für Alleinstehende, für Mitarbeiter\*innen mit Vorerkrankungen oder kranken Angehörigen, für sehr junge Mitarbeiter\*innen (Lehrlinge)? Wie erlebten sie diese Zeiten ununterbrochener Unsicherheit gepaart mit ständig geforderter Flexibilität? Hat sich ihre Vorstellung von Arbeit und ihre Einstellung dazu geändert? Sehen sie darin möglicherweise auch einen Gewinn, eine Chance für eine positive Veränderung? Diese Fragen, und viele mehr, stellte und stelle ich mir permanent selbst und suchte einen Austausch. Mit dem für mich anstehenden Projekt ergab sich somit die Möglichkeit, einen solchen Dialog herstellen zu können. Um weiteren krisenhaften Zeiten vorzubeugen, müssen bestehende und vergangene auch ihre Aufarbeitung finden.

#quote(block: true)[
"Nichtsdestotrotz ist eine historische Wahrheit, dass die großen strukturellen Transformationen der Gesellschaft in der Geschichte häufig das Resultat tiefer sozialer Krisenkonstellationen wie Wirtschaftskrise oder Krieg waren, weil diese ein Business-as-usual verunmöglichten. Krisen sind also tatsächlich gefährliche Wendepunkte, aber insofern diese geschichtsoffen sind, bieten sie eben auch Chancen für eine Entwicklung hin zum Besseren." (Solty, 2021, S. 672)
]

Im gemeinsam gestalteten Hörbild sollten die Stimmen der Mitarbeiter\*innen ihr Gehör finden und diese Zeit für die Stadt Wien - Büchereien damit auch ein Stück weit ihre Dokumentation finden.

== Literatur
<literatur>
Schneider, Magdalena Martha Maria und Volf, Patrik-Paul (2021) "Wir gehen viral! Die Stadt Wien – Büchereien im ersten Lockdown", Mitteilungen der Vereinigung Österreichischer Bibliothekarinnen und Bibliothekare, 73(3-4), S. 473–478. #link("https://doi.org/10.31263/voebm.v73i3-4.5355");.

Solty, Ingar (2021) Krise als Krise / Krise als Chance. Wie aus dem Elend der Gegenwart eine neue demokratischere, sozialere und ökologischere Produktions- und Lebensweise entstehen könnte. In: D.F. Bertz \[Hrsg.\]: Die Welt nach Corona. Von den Risiken des Kapitalismus, den Nebenwirkungen des Ausnahmezustands und der kommenden Gesellschaft. Berlin: Bertz + Fischer Gbr.

Themel, Sarah (2023) "Wir hören einander zu" - Lehrlingsprojekt "Hörbild". Partizipation als Notwendigkeit hin zur Demokratisierung von Arbeitsabläufen. Projektarbeit im Rahmen der hauptamtlichen Ausbildung für Bibliothekar\*innen, 3. Lehrgang, 2019–2021. URL: #link("https://projektarbeiten.bvoe.at/ThemelSarah.pdf")
