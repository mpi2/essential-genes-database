import csv
import os
import re
import sys


def format_family(family):
    if family.lower() == 'gpcr':
        return 'GPCR'
    elif family.lower() == 'ionchannel':
        return 'IonChannel'
    elif family.lower() == 'kinase':
        return 'Kinase'
    else:
        return family

class IDGPreProcessor:

    def __init__(self):

        self.outputfilename = os.path.abspath(os.path.join(os.path.dirname(sys.modules['__main__'].__file__), 'idg_target_list.tsv'))

        self.data = []
        self.sorted_data = []
        self.headings = ['gene', 'idgfamily']

    def test_headings(self, row, headings):

        row_lower = [x.lower() for x in row]

        if row_lower != headings:
            print('The headings of the spreadsheet have changed')
            print('Expected:')
            for index, elem in enumerate(headings):
                print(index, elem)
            print('')
            print('Found:')
            for indexF, elemF in enumerate(row):
                print(indexF, elemF)
            print('')
            print('******************')
            sys.exit('Headers have changed')

    def read_idg_file(self, filename):
        with open(filename, newline='') as f:
            reader = csv.reader(f, delimiter='\t')
            try:
                counter = 0
                for row in reader:
                    counter += 1

                    # Ensure the expected columns are present
                    if counter == 1:
                        self.test_headings(row, self.headings)

                    # Load in the data rows
                    else:
                        # Set the value as the default
                        family = format_family(row[1])
                        self.data.append((row[0], family))

            except csv.Error as e:
                sys.exit('file {}, line {}: {}'.format(self.filename, reader.line_num, e))

            print(str(counter))

    def prepare_data(self):
        unique_data = [list(x) for x in set(x for x in self.data)]
        self.sorted_data = sorted(unique_data, key=lambda entry: entry[0])

    def write_mrk_file(self):
        with open(self.outputfilename, 'w') as f:
            writer = csv.writer(f, delimiter='\t')
            writer.writerow(['Gene', 'IDGFamily'])
            print(str(len(self.sorted_data)))
            try:
                for row in self.sorted_data:
                    writer.writerow([row[0], row[1]])

            except csv.Error as e:
                sys.exit('file {}, line {}: {}'.format(self.outputfilename, writer.line_num, e))


if __name__ == '__main__':
    processor = IDGPreProcessor()
    files = [x for x in os.listdir('.') if re.match('idg_target_list_[a-zA-Z0-9]+.tsv', x)]
    for f in files:
        print(f)
        processor.read_idg_file(f)
    processor.prepare_data()
    processor.write_mrk_file()
